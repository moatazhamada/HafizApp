urls=(
  "https://android.quran.com/data/naskh_1280/page002.png"
  "https://android.quran.com/data/width_1280/page002.png"
  "https://files.quran.app/warsh/original/width_1280/page002.png"
  "https://android.quran.com/data/indo_pak/width_1280/page002.png"
  "https://android.quran.com/data/indopak/width_1280/page002.png"
  "https://files.quran.app/indo_pak/width_1280/page002.png"
  "https://files.quran.app/indopak/width_1280/page002.png"
  "https://android.quran.com/data/qalon/width_1280/page002.png"
)
for u in "${urls[@]}"; do
  status=$(curl -o /dev/null -s -w "%{http_code}\n" -L "$u")
  echo "$status : $u"
done
