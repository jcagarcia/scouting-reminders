#/bin/bash

COMMAND=$1;
FILE=$2;
NOTE=$3;
ROOT_PATH=.scouting_hooks
REMINDERS_FILE=$ROOT_PATH/reminders

function install() {
  echo
  echo "Installing scouting reminders in this git project...";

  create_files;
  configure_git;
}

function add_reminder() {
  echo "Adding $FILE to the reminders list of boy scouting action. \n The reminder note says: $NOTE";

  echo "$FILE    |    $NOTE" >> $REMINDERS_FILE
}

function list_reminders() {
  echo "These are the reminders added by your team for this project:"
  echo
  echo "    TITLE    |    SCOUTING COMMENT"
  echo "---------------------------------------"
  while IFS= read -r line
  do
    echo "- $line"
  done < $REMINDERS_FILE
}

function apply() {
  remove_reminder $FILE 1;
}

function apply_all() {
  remove_reminder $FILE 0;
}

function remove() {
  remove_reminder $FILE 1;

  echo "The file $FILE has been removed from the scouting reminders";
}

function uninstall() {
  echo
  echo "Uninstalling scouting reminders from this git project..."
  rm -r $ROOT_PATH
}

function show_installation_advert() {
  installation_msg="Scouting reminders uses git hooks. The hooks folder of this project will be overridden in order to share the hooks with all the team members. Do you want to coninue? (y/N) "
  read -p "$installation_msg" -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "Scouting reminders not installed. No changes applied to this git project. Exiting...";
    exit 1;
  fi
}

function before_install() {
  if [[ -d $ROOT_PATH ]]; then
    echo "Scouting reminders already installed in this repository";
    exit 1;
  fi;

  show_installation_advert;
}

function before_uninstall() {
  if ! [[ -d $ROOT_PATH ]]; then
    echo "Scouting reminders is not installed in this project yet. Use \"install\" command for installing it.";
    exit 1;
  fi;
  show_uninstall_advert;
}

function before_add() {
  check_add_parameters;
}

function check_add_parameters() {
  if [[ -z $FILE ]]; then
    echo "ERROR. You must provide the file or folder you want to add a scouting reminder.";
    exit 1;
  fi

  if [[ -z $NOTE ]]; then
    echo "ERROR. You must provide a description for this scouting reminder.";
    exit 1;
  fi
}

function show_uninstall_advert() {
  uninstall_msg="Scouting reminders will be removed from this project and all the reminders will be deleted. Do you want to coninue? (y/N) "
  read -p "$uninstall_msg" -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "Scouting reminders not removed from this project :)";
    exit 1;
  fi
}

function validate_directory() {
  if ! [[ -d .git ]]; then
    echo "This directory does not contain a git projecty. Exiting...";
    exit 1;
  fi;
}

function create_files() {
  echo " Creating the needed files..."

  mkdir $ROOT_PATH
  touch $REMINDERS_FILE
  echo '
  echo "Checking scouting reminders..."
  ' > $ROOT_PATH/pre-commit
  chmod 777 $ROOT_PATH/pre-commit
}

function configure_git() {
  echo " Configuring git to use $ROOT_PATH as the new hooks folder..."
  git config core.hooksPath $ROOT_PATH
}

function remove_reminder() {
  file_to_delete=$1;
  delete_all=$2;
  line_to_delete=1;
  something_deleted=1;
  while IFS= read -r line
  do
    file_name="$(cut -d'|' -f1 <<<"$line" | xargs)"
    if [[ $file_name == $file_to_delete ]]; then
      sed "${line_to_delete}d" $REMINDERS_FILE > "${REMINDERS_FILE}.tmp"
      rm $REMINDERS_FILE
      mv "${REMINDERS_FILE}.tmp" $REMINDERS_FILE

      something_deleted=0;

      if ! [ $delete_all -eq 0 ]; then
        break;
      fi;
    else
      line_to_delete=$((line_to_delete+1))
    fi;
  done < $REMINDERS_FILE

  if [ $something_deleted -eq 0 ]; then
    echo "Congratulations! You have completed a file pending of scouting. You are the best scout in the city! :)";
  else
    echo "The provided file $file_to_delete does not match any reminder. Use \"list\" command to check the list of reminders."
  fi;
}

validate_directory

case $COMMAND in
  "install")
    before_install;
    install;
  ;;
  "add")
    before_add;
    add_reminder;
  ;;
  "list")
    list_reminders;
  ;;
  "apply")
    apply;
  ;;
  "apply-all")
    apply_all;
  ;;
  "remove")
    remove;
  ;;
  "uninstall")
    before_uninstall;
    uninstall;
  ;;
esac

