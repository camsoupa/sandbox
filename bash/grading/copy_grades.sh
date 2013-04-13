

exec 3<&0

echo "*********************************************************************************************************"

while read filename ; do
  echo ""
  echo "$(grep -h "Student" "${filename:2}")"  
  echo "$(grep -ih "Score" "${filename:2}")"
  putclip < "${filename:2}"
  echo ""
  echo "Student score report copied to clipboard.  Press any key for next student..."
  echo
  echo "*********************************************************************************************************"
  echo 
  read -n 1 -s <&3

done < <(find -name "*.txt")

