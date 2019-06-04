# spm
스프링 부트 프로세스 매니저 - 스프링 프로세스를 pm2 처럼 관리하고 싶어서 만들어 봄

[영문](https://github.com/juneyoung/spm)

현재로썬 제약이 있음
- OSX 에서 테스트 했음 (awk 나 sed 의 OS 의존 때문에 Linux 에서 문제가 될 수 있음)
- 그레들 fat war 로만 기동가능 (`gradle bootWar` 명령어로 생성된 war 파일 - 하위 라이브러리가 포함된 war 여야 함)

## 1. 설치

지금 버전에서는 심볼릭 링크를 만들어서 전역에서 사용할 수 있도록 해야 함. 설치 파일은 다음 마일스톤에서 제공될 예정임

```
# sh 파일로 연결되는 심볼릭 링크를 생성 
$> ln -s {path_to_file}/spm.sh {system_path}/spm
```

## 2. 사용법

##### a. man 페이지

```
# 위에서 생성한 심볼릭 링크 경로를 $PATH 에 추가했다고 가정
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

##### b. 기동 

pm2 처럼 해당 실행 파일(war) 가 있는 디렉토리에서 실행해야 함

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

##### b. 명령어 목록

| 명령어 | 인수 | 작동 | 예시 |
|-------------|------------|---------|--------|
|start| profile - 부트 프로파일, warFile - 그레들 fat war | 주어진 프로파일로 웹서비스 기동. | spm start dev test.war |
|stop| profile - 부트 프로파일 | 주어진 프로파일에 해당하는 웹서비스 중지 | spm stop dev |
|restart| 작업중... | 작업중... | 작업중... |
|list| 없음 | 관리되는 프로세스 목록 출력 | spm list |
|logs| profile - 부트 프로파일 | 주어진 프로파일에 해당하는 로그 출력 | spm logs dev | 

## 3. 세부 구현

프로세스를 관리하기 위해 정적 디렉토리 구조가 필요함. `DATA_PATH`, `LOG_PATH` 인자가 실행 유저가 접근할 수 있는 경로여야만 함.

`start` 명령어 실행시, 
- 내부적으로 `java` 를 실행하여 그레들 bootWar 파일을 기동함.
- `$DATA_PATH/temp.data` 에 이후 작동을 위하여 데이터를 저장함.

`stop` 명령어 실행시,
- 내부적으로 `kill` 명령어를 실행. 주어진 프로파일로 `temp.data` 에 저장된 데이터를 색인하여 pid 를 찾음
- 데이터 파일에서 해당 프로파일에 해당하는 줄을 삭제함

`logs` 명령어 실행시,
- `$LOG_DATA/${spring.profiles.active}/out.log` 파일에 대하여 `tail` 명령어를 실행함.

bash 에서 테이블을 출력하기
- [이 스택오버플로우 코드릿](https://stackoverflow.com/questions/12768907/how-to-align-the-columns-of-tables-in-bash) 의 코드를 재활용했음 (100 점짜리 코드)

## 4. 알려진 문제점

- 불편한 설치 방법
- OS 의존성 - 홈 사용자 홈 디렉토리라든가... 셔뱅이라든가...
- 그외 알려지지 않은 불편함들이 아주 많음
