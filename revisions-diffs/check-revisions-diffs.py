import argparse
import gitlab
import os
import re

API_CHANGES, KAT_CHANGES        = 0, 0
FIRST_REVISION, SECOND_REVISION = None, None

GITLAB_URL   = os.getenv('GITLAB_URL')
GITLAB_TOKEN = os.getenv('GITLAB_TOKEN')
PROJECT_ID   = os.getenv('PROJECT_ID')

INCLUDE_DIR        = 'include/tii-cryptolib'
KAT_FILE_EXTENSION = '.kat'
KAT_TESTS_DIR      = 'tests/kat'
REPORT_PATH        = 'revisions-diffs-report.html'

def get_report_header(lht_name, rht_name):
  title = f"Diffs between revisions {FIRST_REVISION} and {SECOND_REVISION}" 
  report_header  = f"<!doctype html><html><head><title>{title}</title>"
  report_header += '<style>table {border: 1px solid #cccccc;}'
  report_header += 'td {padding: 10px; text-align: center; vertical-align: middle;}'
  report_header += '.top-border {border-top: 1px solid #cccccc;}'
  report_header += f"</style></head><body><div align='center'><h1>{title}</h1></div>"
  report_header += "<table align='center'>"

  return report_header

def does_tag_exist(project, tag_name):
  result = False

  try:
    tag = project.tags.get(tag_name)
    result = True
  except gitlab.exceptions.GitlabGetError:
    print(f"--- Tag '{tag_name}' does not exist.")
  except Exception as ex:
    print(f"--- An unexpected exception occurred while validating tag '{tag_name}':")
    print(f"--- {ex}.")

  return result

def get_tags(project):
  tags = []

  for page in range(1, 10):
    tags_query = project.tags.list(per_page = 20, page = page)

    if not tags_query:
      break

    tags += tags_query

  return tags

def get_tag_by_regex(project):
  result = None
  tags   = get_tags(project)

  for tag in tags:
    if re.match(r"^v\d*\.\d*\.\d*-develop", tag.name):
      result = tag.name
      break

  return result

def does_branch_exist(project, branch_name):
  result = False

  try:
    branch = project.branches.get(branch_name)
    result = True
  except gitlab.exceptions.GitlabGetError:
    print(f"--- Branch '{branch_name}' does not exist.")
  except Exception as ex:
    print(f"--- An unexpected exception occurred while validating branch '{branch_name}':")
    print(f"--- {ex}.")

  return result

def get_revision(project, revision_name, default_to_branch):
  result = 'develop'

  if revision_name:
    if does_tag_exist(project, revision_name):
      result = revision_name
    else:
      if default_to_branch:
        if does_branch_exist(project, revision_name):
          result = revision_name
      else:
        result = get_tag_by_regex(project)
  elif not default_to_branch:
    result = get_tag_by_regex(project)

  return result

def get_tags_diffs(lht_name, rht_name):
  global FIRST_REVISION
  global SECOND_REVISION

  gl      = gitlab.Gitlab(url = GITLAB_URL, private_token = GITLAB_TOKEN)
  project = gl.projects.get(PROJECT_ID)

  FIRST_REVISION  = get_revision(project, lht_name, True)
  SECOND_REVISION = get_revision(project, rht_name, False)

  comparison = project.repository_compare(FIRST_REVISION, SECOND_REVISION)

  return comparison['diffs']

def get_affected_lines_partial_report(removed_lines, added_lines):
  partial_report = ''
  row            = "<tr><td><b>{}</b></td><td><div align='left'><i>{}</i></div></td></tr>"

  if not removed_lines:
    partial_report += row.format('Lines removed', 'None')
  else:
    partial_report += row.format('Lines removed', removed_lines[0])

    for i in range(1, len(removed_lines)):
      partial_report += row.format('', removed_lines[i])

  if not added_lines:
    partial_report += row.format('Lines added', 'None')
  else:
    partial_report += row.format('Lines added', added_lines[0])

    for i in range(1, len(added_lines)):
      partial_report += row.format('', added_lines[i])

  return partial_report

def process_diff_line(diff, removed_lines, added_lines, partial_report):
  diff_report = ''

  if removed_lines or added_lines:
    diff_report += get_affected_lines_partial_report(removed_lines, added_lines)

  diff_report += "<tr><td>---</td><td><div align='left'>---</div></td></tr>"
  diff_report += f"<tr><td><b>Diff</b></td><td><div align='left'>{diff}</div></td></tr>"

  return diff_report

def did_api_change(regex_match):
  global API_CHANGES

  result = False

  if re.match(r"^\w*\s\w*\(", regex_match if regex_match else ''):
    API_CHANGES += 1
    result       = True

  return result

def did_kat_file_change(filename):
  global KAT_CHANGES

  result = False

  if os.path.splitext(filename)[1] == KAT_FILE_EXTENSION:
    KAT_CHANGES += 1
    result       = True

  return result

def get_partial_report(file_diff, add_top_border, filename):
  old_line, new_line         = 1, 1
  removed_lines, added_lines = [], []

  top_border      = "<td class='top-border'>" if add_top_border else '<td>'
  partial_report  = f"<tr>{top_border}<b>File name</b>{top_border}"
  partial_report += f"<div align='left'>{filename}</div></td></tr>"

  for line in file_diff['diff'].splitlines():
    d = re.match(r"^\@\@ -(\d*),\d* \+(\d*),\d* \@\@", line)
    if d is not None:
      diff     = d.group(0)
      old_line = int(d.group(1)) - 1
      new_line = int(d.group(2)) - 1

      partial_report += process_diff_line(diff, removed_lines, added_lines, partial_report)
      removed_lines, added_lines = [], []

    r = re.match("^\-(.*)", line)
    if r is not None:
      new_line   -= 1
      regex_match = r.group(1)

      if did_api_change(r.group(1)) or did_kat_file_change(filename):
        removed_line = f"{old_line} | {regex_match if regex_match else 'Blank line'}"
        removed_lines.append(removed_line)

    a = re.match("^\+(.*)", line)
    if a is not None:
      old_line   -= 1
      regex_match = a.group(1)

      if did_api_change(a.group(1)) or did_kat_file_change(filename):
        added_line = f"{new_line} | {regex_match if regex_match else 'Blank line'}"
        added_lines.append(added_line)

    old_line += 1
    new_line += 1

  partial_report += get_affected_lines_partial_report(removed_lines, added_lines)

  return partial_report

def get_report_footer():
  report_footer = '</table></body></html>'

  return report_footer

def save_report(final_report):
  with open(REPORT_PATH, 'w') as file:
    file.write(final_report)

if __name__ == '__main__':
  parser = argparse.ArgumentParser(
    prog = 'Git tags comparator',
    description = 'Compares two given tags and outputs the diffs to an HTML file.')

  parser.add_argument('-lht', dest = 'lht_name', help = 'The most recent tag name')
  parser.add_argument('-rht', dest = 'rht_name', help = 'The second to most recent tag name')

  args           = parser.parse_args()
  tags_diffs     = get_tags_diffs(args.lht_name, args.rht_name)
  final_report   = get_report_header(args.lht_name, args.rht_name)
  add_top_border = False
  exit_code      = 0

  for file_diff in tags_diffs:
    filename = file_diff['new_path']
    dirname  = os.path.dirname(filename)

    if dirname != INCLUDE_DIR and dirname != KAT_TESTS_DIR:
      continue

    final_report  += get_partial_report(file_diff, add_top_border, filename)
    add_top_border = True

  final_report += get_report_footer()

  if API_CHANGES > 0:
    print(f"--- {API_CHANGES} API change(s) detected.")
    print('--- Please, proceed as follows:')
    print('---   1. Regenerate configuration files for fuzzing and constant time tools.')
    print('---   2. Check that the corresponding tests are using the correct new API.')
    print("---   3. Make sure the changes are reported in changelog and release notes.\n")
    exit_code = 1

  if KAT_CHANGES > 0:
    print(f"--- {KAT_CHANGES} KAT change(s) detected.")
    print('--- This could imply a backward incompatible change. Please, proceed as follows:')
    print("---   1. Make sure the changes are reported in changelog and release notes.\n")
    exit_code = 1

  if API_CHANGES > 0 or KAT_CHANGES > 0:
    save_report(final_report)
    print(f"--- Review the changes at {REPORT_PATH}.")

  exit(exit_code)
