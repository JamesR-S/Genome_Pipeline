process CHECK_SOMETHING {
  tag "$id"
  input:
    tuple val(id), file(someFile)

  // we’ll echo “true” or “false” but always exit with code 0
  output:
    stdout

  script:
  """
  #!/usr/bin/env bash
  # some condition on your file...
  if ! [ -f /path/to/file ]; then
    echo true
  else
    echo false
  fi
  """
}