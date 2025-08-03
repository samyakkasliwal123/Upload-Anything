import os
import re
import fire


def inc_patch(version):
    major, minor, patch = version.strip("v").split('.')
    return "v{}.{}.{}".format(major, minor, int(patch) + 1)

def inc_minor(version):
    major, minor, patch = version.strip("v").split('.')
    return "v{}.{}.{}".format(major, int(minor)+1, patch)


def inc_major(version):
    major, minor, patch = version.strip("v").split('.')
    return "v{}.{}.{}".format(int(major)+1, minor, patch)


if __name__ == "__main__":
    fire.Fire({
        'inc-patch': inc_patch,
        'inc-minor': inc_minor,
        'inc-major': inc_major
    })