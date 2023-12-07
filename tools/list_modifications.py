#!/usr/bin/env python3

import pathlib
import subprocess
import tabulate


def main():
    repo_root = pathlib.Path(__file__).resolve().parents[1]
    vagrantfiles = []
    for git_file in subprocess.check_output(
            ("git", "ls-tree", "-r", "--name-only", "HEAD"),
            universal_newlines=True, text=True,
            cwd=repo_root
    ).splitlines():
        if git_file.split("/")[-1] == "Vagrantfile":
            modified_date = subprocess.check_output(
                ("git", "log", "-1", '--format=%ai', "--", git_file),
                universal_newlines=True, text=True,
                cwd=repo_root
            ).strip()
            vagrantfiles += [[git_file, modified_date]]
    vagrantfiles.sort(key=lambda x: x[1])
    print(tabulate.tabulate(vagrantfiles, headers=["Vagrantfile", "Modified"]))


if __name__ == "__main__":
    main()
