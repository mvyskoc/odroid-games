#!/usr/bin/python
import subprocess
import os
import sys
import re
import argparse


RE_LDD_LIB=re.compile(r"\s*(.+?)(?:\s=>\s(.+?))?\s\((0x[0-9A-Fa-f]+)\)")
RE_DPKG=re.compile(r"(.+?)(?::(.+?))?:\s()(.+?)")

DEFAULT_EXCLUDE=[
    'linux-vdso.so', 
    'libc.so',
    'libpthread.so',
    'libdl.so',
    'ld-linux-x86-64.so',
    'libm.so',
    'libnsl.so',
    'librt.so',
    'libnsl.so',
    'libmvec.so',
    'libgcc_s.so',
    'libcrypt.so',
    'libnss_compat.so',
    'libnss_dns.so',
    'libnss_files.so',
    'libresolv.so',
    'libutil.so',
    'libz.so',
    'libmvec.so'
]

def get_required_libs(executable):
    result = []
    prg_out = subprocess.check_output(
        ['ldd', os.path.abspath(executable)], 
        shell=False).decode('utf-8')

    for line in prg_out.split('\n'):
        m = RE_LDD_LIB.match(line)
        if m:
            lib_name, lib_path, lib_addr = m.groups()
            if lib_path:
                result.append(lib_path)

    return set(result)

def get_required_libs2(exec_list):
    result = []
    for exe in exec_list:
        result.extend(get_required_libs(exe))
    
    return set(result)

def exclude_libs(req_list, exclude_list):
    result = []
    for lib_path in req_list:
        path, lib_name = os.path.split(lib_path)
        is_excluded = False
        for ex_name in exclude_list:
            if lib_name.startswith(ex_name):
                is_excluded = True
        if not is_excluded:
            print("Exclude: {}".format(lib_path))
            result.append(lib_path)
    
    return set(result)

def get_package_name(lib_path):
    repeat_cnt = 0
    result = ''
    while repeat_cnt < 2:
        try:
            prg_out = subprocess.check_output(
                ['dpkg', '-S', lib_path], 
                shell=False).decode('utf-8')
            
            for line in prg_out.splitlines():
                m = RE_DPKG.match(line)
                if m:
                    result = m.group(1)
            repeat_cnt = 2
        except subprocess.CalledProcessError:
            repeat_cnt += 1
            lib_path = os.path.split(lib_path)[1]

    return result

def get_required_packages(lib_path_list):
    packages = set()
    libs = set()
    for lib_path in lib_path_list:
        pkg_name = get_package_name(lib_path)
        if pkg_name:
            packages.add(pkg_name)
        else:
            libs.add(lib_path)

    return packages, libs

def print_list(element_list):
    for element in element_list:
        print('  - {}'.format(element))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('executables', type=str, nargs='+',
                    help='Path to the executable files')
    parser.add_argument('--exclude', '-e', type=str, nargs='+', default=[],
                    help='Names of excluded libs')

    args = parser.parse_args()
    required_libs = get_required_libs2(args.executables)
    required_libs = exclude_libs(required_libs, args.exclude)
    required_libs = exclude_libs(required_libs, DEFAULT_EXCLUDE)
    packages, not_found_libs = get_required_packages(required_libs)
    print("Required packages")
    print_list(packages)
    print("")
    print("Required libs from host computer:")
    print_list(not_found_libs)


if __name__ == '__main__':
    main()
