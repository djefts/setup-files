# whos using this port???
whos_on() {
  sudo ss -lptn 'sport = :"$1"'
}
