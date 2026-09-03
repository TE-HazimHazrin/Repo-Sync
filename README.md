# Repo-Sync
To automate delete old environment and sync new environment

How to:

Step 1 (run once)
chmod +x build_environment.sh

Step 2 (create screen)
screen -S my_session_name

Step 3 (run the script)
./build_environment.sh

Operation
1. Delete old directory (if user specifies)
2. Create new directory
3. Do repo sync with tag
4. Enter Docker
5. Do full build
6. After finish, will remain in docker condition

DISCLAIMER
Continue at own risk
