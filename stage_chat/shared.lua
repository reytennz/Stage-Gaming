function RGBToHex(red, green, blue)
  red = tonumber(red) or 255
  green = tonumber(green) or 255
  blue = tonumber(blue) or 255
  if red < 0 or red > 255 or green < 0 or green > 255 or blue < 0 or blue > 255 then
    return "#FFFFFF"
  end
  return string.format("#%.2X%.2X%.2X", red, green, blue)
end
