CalculatorApp = CalculatorApp or {}
function CalculatorApp.open()
    if Phone and Phone.setPage then
        Phone.setPage("calculator")
    end
end
function CalculatorApp.press(key)
    if Phone and Phone.calcPress then
        Phone.calcPress(key)
    end
end
