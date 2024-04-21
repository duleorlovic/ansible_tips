# Ansible tips

Ansible is a nice tools since it does not store the state anywhere, instead, it
uses a gather facts step before deploying so it will skip the step if not
needed (changed = 0)

https://docs.ansible.com/ansible/latest/getting_started/index.html

Inventory file can be in `INI` (text) or `YAML` format.
(default is `/etc/ansible/hosts`)

```
# inventory.yml
name_of_group:
  hosts:
    my-host.com:
      my_variable: 123 # host variable

    my-other-vm:
      ansible_host: my-other-vm.com # overwrite ansible variable

  vars: # group variables
    ntp_server: example.com

name_of_another_group:
  children:
    name_of_group:
    # this means all hosts from name_of_group are also hosts in parent group. If
    # you use multiple files child group should be loaded before parent
```

same in INI format
```
# inventory.ini
[name_of_group]
my-host.com my_variable=123
my-other-vm ansible_host=my-other-vm.com
```

Some example commands
```
# list hosts
ansible -i inventory.yml all --list-hosts

# ah hock commands using modules
ansible -i inventory.yml all -m ping

# you can overwrite inventory
export ANSIBLE_INVENTORY=~/web-tips/ansible_tips/sample/inventory.yml
# or config file
# ansible.cfg
[defaults]
inventory = ~/web-tips/ansible_tips/sample/inventory.yml
# so following command is using env or config so it does not need params
ansible all -m ping

# default module "command" so you do not need to write "-m command"
ansible all -a ls

# instead of all (or *) you can use group name like virtualmachines
# !excluded_group,&intersection_group
ansible virtualmachines -m service -a "name=httpd state=restarted"

# you can also target using limit option
ansible all -m service -a "name=httpd state=restarted" --limit virtualmachines
```

https://docs.ansible.com/ansible/latest/getting_started/basic_concepts.html

- control node: machine that run ansible cli tools
- managed nodes: ie target hosts on which we run commands (no need ansible to be
  installed, but python is required to run ansible generated code)
- inventory: a list of managed nodes, hostfile specifies groups
- playbooks: describe execution concept and files on which `ansible-playbook`
  operates
- play: maps managed node (target) to tasks, contains variables, roles and tasks
- role: limited distribution of reusable ansible content (task, handler,
  variable, plugin, template and file)
- task: action applied to managed host
- handler: special form of task, that executes when notified by a previous task
  which resulted in changed status

## Installing

Install using pip
https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

With pipx
```
sudo apt install pipx

pipx install --include-deps ansible
```

With pip
```
python3 -m pip install --user ansible
# make sure it is in path, otherwise put in bashrc
# pip installed ansible command should be accessible
# export PATH=~/.local/bin:$PATH
ansible --version
ansible [core 2.15.5]

python3 -m pip install --user argcomplete
activate-global-python-argcomplete --user
```
If installed using package manager, than config is in `/etc/ansible`

Install ansible-navigator
```
python3 -m pip install ansible-navigator --user
```

Vim plugins
https://docs.ansible.com/ansible/latest/community/other_tools_and_programs.html#vim


## Host key check

When server is reinstalled than known_hosts will not have the key so it will
prompt for confirmation of the new key. You can disable this check in
`/etc/ansible/ansible.cfg` or `~/ansible.cfg` or `my-app/ansible.cfg`
```
[defaults]
host_key_checking = False
```
or environment variable
```
export ANSIBLE_HOST_KEY_CHECKING=False
# or
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook
```

For access over ssh as root you need to enabled on target machine
```
sudo vi /etc/ssh/sshd_config
PermitRootLogin yes

sudo service ssh restart
```

so on control machine you can copy keys
```
ssh-copy-id root@192.168.88.241
```

## Become

When you need sudo priviledges you can use become
https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_privilege_escalation.html#become
To specify a password for sudo, run ansible-playbook with `--ask-become-pass`
(-K for short). If you run a playbook utilizing become and the playbook seems to
hang, most likely it is stuck at the privilege escalation prompt. Stop it with
CTRL-c, then execute the playbook with -K and the appropriate password.

Eg rebooting servers
```
ansible virtualmachines -a "reboot" --become --ask-become-pass
```

## Ad hock manual managing files, packages, users and services


https://docs.ansible.com/ansible/latest/command_guide/intro_adhoc.html#managing-files
```
# copy file
ansible all -m ansible.builtin.copy -a "src=./playbook.yaml dest=~"

# remove file
ansible all -m ansible.builtin.file -a "path=./playbook.yaml state=absent"

# install package, use root user or ask for pass
ansible all -m ansible.builtin.apt -a "name=vim state=latest" -u root
ansible all -m ansible.builtin.apt -a "name=vim state=latest" --become --ask-become-pass
# remote package
ansible all -m ansible.builtin.apt -a "name=vim state=absent" -u root

# create user
ansible all -m ansible.builtin.user -a "name=foo password=pass"

# restart service
ansible webservers -m ansible.builtin.service -a "name=httpd state=restarted"
```

Get all info
```
ansible all -m ansible.builtin.setup
```
Check mode without actually running it with `--check` option
```
ansible all -m ansible.builtin.copy -a "src=./playbook.yaml dest=~" -C
```

## Playbook

Run playbook
```
ansible-playbook -i inventory.yml  playbook.yaml
```
you can set invetory file in env
```
export ANSIBLE_INVENTORY=~/web-tips/ansible_tips/sample/inventory.yml

ansible-playbook playbook.yaml
```
set variable
```
ansible-playbook playbook.yaml -e my_var=foo
```

Test and verify without actuall change with those options: --check, --diff,
--list-hosts, --list-tasks, and --syntax-check

Run on controller machine using `connection: local` or changing `hosts:
127.0.0.1`
```
# playbook.yml
- hosts: 127.0.0.1

# or
- hosts: virtualmachines
  connection: local
```

Playbook keywords https://docs.ansible.com/ansible/latest/reference_appendices/playbooks_keywords.html#playbook-keywords
* `remote_user` playbook keyword (`ansible_user` in hosts file) is used for ssh
  connection (default in configuration is DEFAULT_REMOTE_USER) or `-u` on cli
* `register: file_contents` is used on play to save the output of module return
  data to a variable, so you can `debug: { var: file_contents.stdout }` to print
* `loop: [{ attr: 1 }, { attr: 2}]` is used to loop current play
* `block: []` is used to group tasks so you can apply same directive or data for
  all tasks in a block
* `handlers:` list of tasks to run when `notify:` is on task that is `changed`

Old index of all modules https://docs.ansible.com/ansible/2.9/modules/modules_by_category.html#modules-by-category

Template module https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_templating.html
```
# templates/test.j2
My name is {{ ansible_facts['hostname'] }}

# main.yml
    - name: write hostname to test.txt file
      ansible.builtin.template:
        src: templates/test.j2
        dest: test.txt
```

Filters  https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_filters.html
Standard jinja2 filters https://jinja.palletsprojects.com/en/3.1.x/templates/#builtin-filters
Ansible allows jinja2 loops and conditionals in templates, but not in playbooks
(playbooks are pure machine parseable yaml). Template is processed on controller
and only the result is sent to target machine.
```
# use default 5 if some_variable is not defined
{{ some_variable | default(5) }}
# use default admin even it is false or empty string
{{ lookup('env', 'MY_USER') | default('admin', true) }}

# optional variable with `omit`, so mode is not set when item.mode is blank
mode: "{{ item.mode | default(omit) }}"

# by default variable is required unless DEFAULT_UNDEFINED_VAR_BEHAVIOR=false so
# in this case you need to mandatory require variable
{{ variable | mandatory }}

# required with message
galaxy_api_key: "{{ undef(hint='You must specify your Galaxy API key') }}"

# different value for true false or null
{{ enabled | ternary('no shutdown', 'shutdown', omit) }}

# transform dict hash to list array of key: value: objects
{{ dict | dict2items }}
# or list to dictionary
{{ tags | items2dict }}

# convert
{{ some_variable | to_json }}
{{ some_variable | to_yaml }}
{{ some_variable | to_nice_json }}
{{ some_variable | to_nice_yaml }}
{{ some_variable | from_json }}
{{ some_variable | from_yaml }}

# comobine with filters
```
TODO: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_filters.html#combining-and-selecting-data

Test if variable is matching some string `when: var is `
https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_tests.html#playbooks-tests
Standard comparisons https://jinja.palletsprojects.com/en/latest/templates/#comparisons
```
vars:
  url: "https://example.com/users/foo/resources/bar"

tasks:
  - debug:
      msg: "matched pattern 4"
    when: url is regex("example\.com/\w+/foo")
```
Test if list contains a value
```
vars:
  lacp_groups:
    - master: lacp0
      network: 10.65.100.0/24
      interfaces:
        - em1
        - em2

tasks:
  - debug:
      msg: "{{ (lacp_groups|selectattr('interfaces', 'contains', 'em1')|first).master }}"
```

Check task result with `register: name` and use `name.stdout`
https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_conditionals.html#conditions-based-on-registered-variables
```
tasks:
  - shell: /usr/bin/foo
    register: result
    ignore_errors: true # continue with tasks event this task fails

  - debug:
      msg: "it failed"
    when: result is failed

  # in most cases you'll want a handler, but if you want to do something right now, this is nice
  # this will executed if task that registered "result" variable changed something
  - debug:
      msg: "it changed"
    when: result is changed
```
You can create loop from variable
```
- name: Registered variable usage as a loop list
  hosts: all
  tasks:
    - name: Retrieve the list of home directories
      ansible.builtin.command: ls /home
      register: home_dirs

    - name: Add home dirs to the backup spooler
      ansible.builtin.file:
        path: /mnt/bkspool/{{ item }}
        src: /home/{{ item }}
        state: link
      loop: "{{ home_dirs.stdout_lines }}"
      # same as loop: "{{ home_dirs.stdout.split() }}"
```
You should use `|bool` filter for string like `"true", "yes"`
```
  tasks:
    - name: Run the command if "epic" or "monumental" is true
      ansible.builtin.shell: echo "This certainly is epic!"
      when: epic or monumental | bool
```
Check if var is defined. Note that it is different `import_tasks` (static,
condition is applied to every task, so debug step will be skipped since x is not
defined) and `include_tasks` (condition is applied only to the include
statement, so debug step will not be skipped)
```
# all tasks within an imported file inherit the condition from the import statement
# main.yml
- hosts: all
  tasks:
  - import_tasks: other_tasks.yml # note "import"
  # - include_tasks: other_tasks.yml # note "include"
    when: x is not defined

# other_tasks.yml
- name: Set a variable
  ansible.builtin.set_fact:
    x: foo

- name: Print a variable
  ansible.builtin.debug:
    var: x
```
Conditionals https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_conditionals.html
```
tasks:
  - name: Shut down Debian flavored systems
    ansible.builtin.command: /sbin/shutdown -t now
    when: ansible_facts['os_family'] == "Debian"

```


Loops https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_loops.html
repeat the block witn interpolation `"{{ item }}"`.
When iterating a list of hashes you can reference with `"{{ item.key_name }}"`.
Note that some plugins accepts list so it is better to provide a list than to
use a loop (since it will not iterate one by one, for example `apt` module)
When you are registering variable in a loop than result is a list in
`register_name.results`
```
- name: Register loop output as a variable
  ansible.builtin.shell: "echo {{ item }}"
  loop:
    - "one"
    - "two"
  register: echo
  changed_when: echo.stdout != "one"
- name: Fail if return code is not 0
  ansible.builtin.fail:
    msg: "The command ({{ item.cmd }}) did not have a 0 return code"
  when: item.rc != 0
  loop: "{{ echo.results }}"
```
You can retry
```
- name: Retry a task until a certain condition is met
  ansible.builtin.shell: /usr/bin/foo
  register: result
  until: result.stdout.find("all systems go") != -1
  retries: 5
  delay: 10
```
You can iterate over inventory
```
- name: Show all the hosts in the inventory
  ansible.builtin.debug:
    msg: "{{ item }}"
  loop: "{{ groups['all'] }}"
  # loop: "{{ query('inventory_hostnames', 'all') }}"
  # same as
  # loop: "{{ lookup('inventory_hostnames', 'all', wantlist=True) }}"


- name: Show all the hosts in the current play
  ansible.builtin.debug:
    msg: "{{ item }}"
  loop: "{{ ansible_play_batch }}"
```
Adding `loop_control` keys
```
  loop_control:
    label: "{{ item.name }}" # limit the output to .name instead all item object
    pause: 3 # delay in seconds
    index_var: my_idx # you can use this variable inside the loop
    loop_var: new_item # rename item to new_item, usefull in nested loops with
                       # include_tasks: inner.yml
    extended: true # you can access to eg ansible_loop.length variables
```

Delegating tasks https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_delegation.html
`include`, `add_host` and `debug` are always local task
You can delegate to local machine
```
  tasks:
    - name: Take out of load balancer pool
      ansible.builtin.command: /usr/bin/take_out_of_pool {{ inventory_hostname }}
      delegate_to: 127.0.0.1

    # shorthand is
    - name: Take out of load balancer pool
      local_action: ansible.builtin.command /usr/bin/take_out_of_pool {{ inventory_hostname }}
```
you can run playbook from remote machine
```
- hosts: 127.0.0.1
  connection: local
```

Block https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_blocks.html
is used to apply same data to all tasks and you can rescue when task `failed`
```
tasks:
   - name: Attempt and graceful roll back demo
     block:
       - name: Do something
         ansible.builtin.shell: grep $(whoami) /etc/hosts

       - name: Force a failure, if previous one succeeds
         ansible.builtin.command: /bin/false
     rescue:
       - name: All is good if the first task failed
         when: ansible_failed.task.name == 'Do Something'
         debug:
            msg: All is good, ignore error as grep could not find 'me' in hosts

       - name: All is good if the first task failed
         when: "'/bin/false' in ansible_failed.result.cmd|d([])"
         fail:
            msg: It's still false!!!
```

https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html
Handlers are tasks that are triggered by `notify` if that task make a change.
Handlers are executed after all tasks (or when `meta: flush_handlers` is called)
```
- name: Verify apache installation
  hosts: webservers
  tasks:
    - name: Ensure apache is at the latest version
      ansible.builtin.yum:
        name: httpd
        state: latest

    - name: Write the apache config file
      ansible.builtin.template:
        src: /srv/httpd.j2
        dest: /etc/httpd.conf
      notify:
      - Restart apache

    - name: Ensure apache is running
      ansible.builtin.service:
        name: httpd
        state: started

  handlers:
    - name: Restart apache
      ansible.builtin.service:
        name: httpd
        state: restarted
```
alternatively you can use `listen` topic (interpolation with variables is not
supported)
```
  tasks:
    - name: restart
      notify: "restart web services"

handlers:
  - name: Restart apache
    service:
      name: apache
      state: restarted
    listen: "restart web services"
```
Error handling https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_error_handling.html

```
- name: Do not count this as a failure
  ansible.builtin.command: /bin/false
  ignore_errors: true

  ignore_unreachable: true

  force_handlers: true # run handlers even some task fails

  # specify when the task is failed (even with non zero return code)
  failed_when: diff_cmd.rc == 0 or diff_cmd.rc >= 2

  # stop execution on all hosts
  any_errors_fatal: true
```

Set remove environment https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_environment.html
does not affect ansible configuration, to make them facts you need to use on
explicit `gather_facts` task. It is used mainly for proxy, and PATH
```
- name: Install ruby 2.3.1
  ansible.builtin.command: rbenv install {{ rbenv_ruby_version }}
  args:
    creates: '{{ rbenv_root }}/versions/{{ rbenv_ruby_version }}/bin/ruby'
  vars:
    rbenv_root: /usr/local/rbenv
    rbenv_ruby_version: 2.3.1
  environment:
    CONFIGURE_OPTS: '--disable-install-doc'
    RBENV_ROOT: '{{ rbenv_root }}'
    PATH: '{{ rbenv_root }}/bin:{{ rbenv_root }}/shims:{{ rbenv_plugins }}/ruby-build/bin:{{ ansible_env.PATH }}'
```

https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse.html
You can import playbook statically (before it runs any task in playbook)
```
- import_playbook: "my_playbook.yml"
```

Dynamic `include_` is used in looping, so each loop will execute the task.

Static `import_` is before it runs so it is preprocessed before so not affected
at runtime (eg variable interpolation). You can set vars on each import.
Also options eg `when:` is applied to each child task from imported file.
Can not be used in a loop.
```
- import_tasks: wordpress.yml
  vars:
    wp_user: timmy

- import_tasks: wordpress.yml
  vars:
    wp_user: alice
```

Triggering handlers with include and import
```
- name: Trigger an included (dynamic) handler
  hosts: localhost
  handlers:
    - name: Restart services
      include_tasks: restarts.yml
  tasks:
    - command: "true"
      notify: Restart services

# import
- name: Trigger an imported (static) handler
  hosts: localhost
  handlers:
    - name: Restart services
      import_tasks: restarts.yml
  tasks:
    - command: "true"
      notify: Restart apache
    - command: "true"
      notify: Restart mysql
```
https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html
Roles

Folders in which `main.yml` is loaded
* `tasks/main.yml` main list of tasks that the role executes
* `handlers/main.yml`
* `library/main.yml` modules
* `defaults/main.yml` default variables
* `vars/main.yml` other variables
* `files/main.yml` files
* `templates/main.yml` templates
* `meta/main.yml` metadata

Roles are searched in collections, `roles/` or in playbook folder.
Using roles:
* play level, so for each role `x` it includes `roles/x/tasks/main.yml`,
  `roles/x/handlers/main.yml` ... and order of execution of roles at play level
  is same as static import : `pre_tasks`, handlers by `pre_tasks`, each role
  listead in `roles:` in order listed, `tasks` defined in play, handlers by
  roles or tasks, `post_tasks`, handlers by `post_tasks`
  ```
  - hosts: webservers
    roles:
      - common
      - webservers
      - role: foo_app_instance
        vars:
          app_port: 5000
        tags: typeA
      - { role: foo_app_instance, tags: typeB } # different parameters will
                                                # execute the role again
  ```
* task level, so the order is that first is executed any task before
  `include_role` task, than the role tasks and than other tasks
  ```
  - hosts: webservers
    tasks:
      - name: Print a message
        debug:
          msg: This runs before example role
      - name: Include example role
        include_role:
          name: example
      - name: Include example role
        include_role:
          name: example
        vars:
          app_port: 5000
        tags: typeA # tag is added only to include_role not to all role tasks
      - name: Print a message
        debug:
          msg: This runs after example role
  ```
  similarly `import_role:` task is working like `roles:` just the order is
  listed order, if there is a tag, it is applied to *all* tasks within the role.

Role dependencies are in meta
```
# roles/myrole/meta/main.yml
dependencies:
  - role: common
    vars:
      port: 5000
```

https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_module_defaults.html
Use module defaults so you do not need to repeat params
```
- hosts: localhost
  module_defaults:
    ansible.builtin.file:
      owner: root
      group: root
      mode: 0755
  tasks:
    - name: Create file1
      ansible.builtin.file:
        state: touch
        path: /tmp/file1

    - name: Create file2
      ansible.builtin.file:
        state: touch
        path: /tmp/file2
```

https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html
Variables could be defined in playbook files, command line, or as return value
and can be used as module arguments, when conditionals, templates and loops.
Truthy values: True , 'true' , 't' , 'yes' , 'y' , 'on' , '1' , 1 , 1.0
Falsy values: False , 'false' , 'f' , 'no' , 'n' , 'off' , '0' , 0 , 0.0
List: `my_list: [1]`, access with `my_list[0]`
Dict: `my_dict: {key: value}` access with `my_dict.key` or `my_dict[key]`
(preferred since dot notation could be a problem is key is python reserved
public attributes like `my_dict.add`, `.pop`, `.sort`). Nested variables works
like `{{ ansible_facts["etho"]["ipv4"]["address"] }}`

Define in play using `vars:` attributes
```
# playbook.yml
- hosts: virtualmachines
  vars:
    my_var: my_value
```
Use var files
```
# for vars/RedHat.yml
apache: httpd
somethingelse: 42
```
and
```
- hosts: webservers
  vars_files:
    - "vars/common.yml"
    # use os_defaults.yml if eg vars/ubuntu.yml not found
    - [ "vars/{{ ansible_facts['os_family'] }}.yml", "vars/os_defaults.yml" ]
  tasks:
    - name: Make sure apache is started
      ansible.builtin.service:
        name: '{{ apache }}' # use variable from variable file
        state: started
```
Set variable from fact
```
  tasks:
    - name: Get the CPU temperature
      set_fact:
        temperature: "{{ ansible_facts['cpu_temperature'] }}"

    - name: Restart the system if the temperature is too high
      when: temperature | float > 90
      shell: "reboot"
```
https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_prompts.html
Prompts
```
- hosts: all
  vars_prompt:
    - name: username
      prompt: What is your username?
      private: false
    - name: password
      prompt: What is your password?
  tasks:
    - name: Print a message
      ansible.builtin.debug:
        msg: 'Logging in as {{ username }}'
```

Defining variable at runtime using `--extra-vars` or `-e` argument and json
format for complex vars and use escape if needed
```
ansible-playbook release.yml --extra-vars "version=1.23.45 other_variable=foo"
ansible-playbook release.yml --extra-vars '{"version":"1.23.45","other_variable":"foo"}'
ansible-playbook arcade.yml --extra-vars '{"name":"Conan O'\\\''Brien"}'
```
Variable set in playbook exists only withing the playbook object scope.
Variables associated with a host or group, inventory or `set_fact` or
`include_vars` are available to all plays.
Variable precedence
https://docs.ansible.com/ansible/latest/reference_appendices/general_precedence.html#general-precedence-rules
https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence

CLI values `-u` > role defaults `role/defaults/main.yml` > inventory or script
group vars > inventory `group_vars/all` > playbook `group_vars/all` > inventory
`group_vars/*` > playbook `group_vars/*`> inventory or script host vars >
inventory `host_vars/*` > playbook `host_vars/*` > host facts > play vars > play
`vars_prompt` > play `vars_files` > role vars `role/vars/main.yml` > block vars
(only for tasks in block) > tasks `vars:` > `include_vars` > `set_facts`
registered vars > role and include_role params > include params > extra vars
`-e`

https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html
Facts
You can create local facts using `/etc/ansible/facts.d/preferences.fact` and it
will show as
```
{ "ansible_local": {
    "preferences": {
      "asd": "1"
    }
  }
}
```

 Magic variables like `hostvars` eg gather all IP addresses from group
 ```
 {% for host in groups['app_servers'] %}
   {{ hostvars[host]['ansible_facts']['eth0']['ipv4']['address'] }}
{% endfor %}
 ```

 https://docs.ansible.com/ansible/latest/playbook_guide/guide_rolling_upgrade.html
 Production example rolling upgrade

 https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html
 Validating tasks
 * check mode `ansible-playbook playbook.yml --check`
 * diff mode `ansible-playbook foo.yml --check --diff --limit foo.example.com`

https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_privilege_escalation.html
Privilege escalation become means it will use `sudo`

https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_tags.html
Tags are defined using `tags:` on task, role, import so you can skip
```
ansible-playbook example.yml --tags "configuration,packages"
ansible-playbook example.yml --skip-tags "packages"
```

https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_startnstep.html
Debugging with running from specific task
```
ansible-playbook playbook.yml --start-at-task="install packages"
```
or ask each task yes/no/continue
```
ansible-playbook playbook.yml --step
```
or using debug tag and run only task that will print variable
```
ansible-playbook playbook.yml --tags debug
```
or using `debugger:`
https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_debugger.html
```
[192.0.2.10] TASK: (debug)>
p result._result
p task.args
task.args["data"] = "{{my_var}}"
p task.args
redo
```

https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_strategies.html
strategy linear, or free (some host can continue on other tasks, and not wait
slow host to complete)
Use `serial: 3` attribute to run playbook to 3 and after it completes it runs on
another 3 hosts

# Linter

TODO: https://github.com/yaegassy/coc-ansible

# Deploy Cloudflared tunnel


cloudflared_tunnel_tf
