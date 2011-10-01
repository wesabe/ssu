config()
{
  section=$1
  key=$2

  foundsection=false

  while read line
  do
    if [[ "$foundsection" == true ]]; then
      if [[ "$line" =~ "[*" ]]; then
        break
      elif [[ "$line" =~ "$key="* ]]; then
        echo "${line:$(expr ${#key}+1)}" | tr -d "\r\n"
        break
      fi
    elif [[ "$line" == "[$section]"* ]]; then
      foundsection=true
    fi
  done < application/application.ini
}

info()
{
  echo -e "\033[36m~> $1\033[0m"
}

say()
{
  echo "   $1"
}

yay()
{
  echo -e "\033[32m~> $1\033[0m"
}

warn()
{
  echo -e "\033[33m~> $1\033[0m"
}

die()
{
  echo -e "\033[31m~> $1\033[0m"
  exit 1
}
