import QtQuick
import QtQuick.Controls

SpinBox {
    from: 0
    to: 300
    editable: true

    property string suffix: " px"

    textFromValue: function(value, locale) {
        return Number(value).toLocaleString(locale, 'f', 0) + suffix
    }

    valueFromText: function(text, locale) {
        let re = /\D*(\d*)\D*/
        return parseInt(re.exec(text)[1], 10)
    }

    validator: RegularExpressionValidator { regularExpression: /\D*\d+\D*/ }
}