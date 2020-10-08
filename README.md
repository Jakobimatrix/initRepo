# initRepro

To enforce clang-tidy inside a repository for c, cpp, cxx, h, hpp files.
The init.sh installes clang-tidy on the local machine and a git-hook for the specified repository to check the format before every commit.
Look inside **format_hook** for the enforced clang-version

**USE ONLY FOR NEW REPOSITORIES! OTHERWISE YOU BREAK GIT BLAME**

further reading:
[How-to-use-Clang-Tidy-to-automatically-correct-code](https://github.com/KratosMultiphysics/Kratos/wiki/How-to-use-Clang-Tidy-to-automatically-correct-code)

[githook-clang-format](https://github.com/andrewseidl/githook-clang-format)

## Usage
1. git clone YOUR_REPOSITORY
2. git clone https://github.com/Jakobimatrix/initRepro.git 
3. `cd initRepro/`
4. `chmod +x init.sh`
5. `sudo ./init.sh PATH_TO_YOUR_REPOSITORY`
   
Now every time you commit a file not meeting the clang-format rules you will be asked to format properly.
**This only applies to YOUR_REPOSITORY (local).**

btw. Your IDE probably is able to enforce clang-format upon saving too.
