Cleanup Script and Task Scheduling

Cleanup Script and Task Scheduling
==================================

This Ansible project contains roles to perform cleanup operations on both Windows and Linux hosts and schedule the cleanup tasks.

Windows Cleanup
---------------

The role `cron-win` contains a PowerShell script `cleanup_script.ps1` that performs cleanup operations on temporary and prefetch files on Windows hosts. The cleanup includes deleting files and directories from specific paths.

To schedule the cleanup task, define the desired frequency and time in the `freq.txt` file in the following format:

    
    Daily 12:00
        

The above example schedules the cleanup task to run daily at 12:00 PM. Supported frequencies are `Daily`, `Weekly`, and `Monthly`. By default, if no file is found, we will proceed as `DAILY 10:00`.

To execute the playbook and schedule the task on Windows hosts:

    
    ansible-playbook -i /path/to/inventory_file cleanup_playbook.yml --ask-vault-pass
        

Linux Cleanup
-------------

The role `cron-linux` contains a shell script `cleanup_script.sh` that performs cleanup operations on temporary and cache files on Linux hosts. The cleanup includes deleting files from specific paths.

The cleanup task is scheduled using cron. The default schedule is set to run daily at 4:00 AM. To change the schedule, modify the `hour` parameter in the `cleanup_playbook.yml` file.

To execute the playbook and schedule the task on Linux hosts:

    
    ansible-playbook -i /path/to/inventory_file cleanup_playbook.yml
        

Please ensure that your Ansible control machine has proper access to the hosts and necessary privileges to execute the scripts and schedule tasks.

Ansible Vault
-------------

Sensitive data, such as the administrative password for Windows hosts, is securely stored using Ansible Vault. The password is stored in the `group_vars/all.yml` file, which is encrypted for security.

### How to Use Ansible Vault

1.  Create a `group_vars` directory in the project root.
2.  Inside the `group_vars` directory, create a file named `all.yml` with the following content:

    
    ---
    admin_password: "your_admin_password_here"
        

Replace `"your_admin_password_here"` with the actual password for the Windows administrative user.

3.  Encrypt the `all.yml` file using Ansible Vault. Open your terminal/command prompt, navigate to the project root directory, and run the following command:

    
    ansible-vault encrypt group_vars/all.yml
        

You will be prompted to enter a password for encrypting the file. Make sure to remember this password as you will need it to run the playbook.

4.  After encrypting the file, your directory structure should look like this:

    
    cleanup_playbook.yml
    group_vars/
       └── all.yml
       └── all.yml.vault
    roles/
       ├── cron-linux/
       │   └── tasks/
       │       └── main.yml
       │   └── files/
       │       └── cleanup_script.sh
       └── cron-win/
           └── tasks/
               └── main.yml
           └── files/
               └── cleanup_script.ps1
        

Now, whenever you run the playbook, Ansible will automatically decrypt the `group_vars/all.yml.vault` file using the password you provided during encryption.

Remember to include the `--ask-vault-pass` option when running the playbook:

    
    ansible-playbook -i /path/to/inventory_file cleanup_playbook.yml --ask-vault-pass
        

This will prompt you to enter the Ansible Vault password before running the playbook, ensuring that your sensitive data remains secure.

With this setup, the Ansible playbook will execute both roles on their respective hosts, schedule the cleanup tasks based on the frequency defined in `freq.txt` for Windows and using `cron` for Linux, and display the output of the scripts. The `README.md` file provides documentation for the project's purpose, instructions on how to execute the playbook, and details on using Ansible Vault for secure data management.