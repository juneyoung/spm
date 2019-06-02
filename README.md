# spm
Spring boot process manager.

For now, it will works in following condition
- OSX (If want to test in Linux, have to change shebang)
- Works for gradle fat war (a war file which made with command `gradle bootWar`)

## 1. Installation

Currently, need to make a symbolic link to use it. Intallation file will be provided in the next mile stone

```
# make a symbolic link for sh 
$> ln -s {path_to_file}/spm.sh {system_path}/spm
```

## 2. Usage

##### a. man page

```
# Assume that you register link to $PATH
$> spm
SPM(Spring Process Manager) v.0.01a writen 1st JUN 2019
Required config directory : [ /Users/user/etc/spm/config ] exists. Good to go ...
Required data directory : [ /Users/user/etc/spm/data ] exists. Good to go ...
Required logs directory : [ /Users/user/etc/spm/logs ] exists. Good to go ...
need argument [command] [Spring.profile] for execute ...
command list
  start	[profile] : Start bootWar with given profile
  stop [profile] : Stop bootWar with given profile
  restart [profile] : Retart bootWar with given profile
  logs [profile] : Print out logs with given profile
  list : show managed process list
```

##### b. start 

Execute this command in the directory where the executable war exists

```
# 
$> spm start dev test-0.0.1-SNAPSHOT.war 
SPM(Spring Process Manager) v.0.01a writen 1st JUN 2019
Required config directory : [ /Users/user/etc/spm/config ] exists. Good to go ...
Required data directory : [ /Users/user/etc/spm/data ] exists. Good to go ...
Required logs directory : [ /Users/user/etc/spm/logs ] exists. Good to go ...
Start bootWar and retore data and logs with profile [ dev ]
start new process with  dev
Start [ dev ] with file [ test-0.0.1-SNAPSHOT.war ]
Spring process run with pid [ 11047 ]
+----------+--------+-----------------------+
| profile  | pid    | start_date            |
+----------+--------+-----------------------+
| dev      | 11047  | 2019-06-02 17:56:22;  |
+----------+--------+-----------------------+
```

##### b. Command list

| command | parameters | expected | example |
|-------------|------------|---------|--------|
|start| profile - spring profile, warFile - gradle bootWar file | Run war file with given profile. | spm start dev test.war |
|stop| profile - spring profile | Stop spring boot process with given profile | spm stop dev |
|restart| In progress | In progress | In progress |
|list| none | Show up all managed processes | spm list |
|logs| profile - spring profile | show out logs with given profile | spm logs dev | 

## 3. How it works

It uses some static directories to manage process. Make sure that `DATA_PATH`, `LOG_PATH` are accessable to execute user.

When it `start`, 
- It will execute `java` command to your gradle bootWar.
- It will store some data `$DATA_PATH/temp.data` to operations.

When it `stop`,
- It will execute `kill` command based on `temp.data` file
- It will remove corresponding row in the data file

When it `logs`,
- It will exeute `tail` command on `$LOG_DATA/${spring.profiles.active}/out.log`.

How to make a table in bash
- [This stackoverflow codelit](https://stackoverflow.com/questions/12768907/how-to-align-the-columns-of-tables-in-bash) is an wonderful example

## 4. Known issues

- Inconvenient installation
- OS compatibilities
- And so on 
