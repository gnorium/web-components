/// Convert Int to String with thousands separators
func formatNumberWithCommas(_ n: Int) -> String {
  if n == 0 { return "0" }
  var r = ""
  var m = n
  var c = 0
  while m > 0 {
    if c > 0 && c % 3 == 0 { r = "," + r }
    r = String(m % 10) + r
    m /= 10
    c += 1
  }
  return r
}
