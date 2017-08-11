import os
import sys

def main():
    path_1 = sys.argv[1]
    path_2 = sys.argv[2]

    f1 = open(path_1, 'r')
    f2 = open(path_2, 'r')

    print("Now comparing files: %s and %s" %(path_1, path_2))
    print("*******")

    print("found the following differences:")
    print('')

    f1_line = f1.readline()
    f2_line = f2.readline()

    line = 1

    while f1_line != '' or f2_line != '':
        
        if f1_line != f2_line:
            print("at line:", line)

            print("first")
            print(f1_line)
            print("second")
            print(f2_line)

        f1_line = f1.readline()
        f2_line = f2.readline()

        line+=1

    f1.close()
    f2.close()

    print("finished")

if __name__ == '__main__':
    main()
            
