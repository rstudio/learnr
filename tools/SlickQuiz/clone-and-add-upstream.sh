
if [ ! -d "SlickQuiz" ]; then
  git clone git@github.com:rstudio/SlickQuiz.git
  (cd SlickQuiz && git remote add upstream https://github.com/jewlofthelotus/SlickQuiz.git)
fi


