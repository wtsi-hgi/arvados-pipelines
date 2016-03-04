import sys

class InvalidArgumentError(Exception):
    pass

class FileAccessError(Exception):
    pass

class APIError(Exception):
    pass

if __name__ == '__main__':
    print "This module is not intended to be executed as a script"
    sys.exit(1)
