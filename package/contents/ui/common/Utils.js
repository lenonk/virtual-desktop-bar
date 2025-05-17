.pragma library

/**
 * Creates a timer for delayed execution of a callback function
 * @param {number} milliseconds - Delay duration in milliseconds
 * @param {Function} callbackFunc - Function to execute after delay
 * @returns {Timer} Timer object
 */
function delay(milliseconds, callbackFunc, parentObj) {
    if (!parentObj) {
        console.error("Utils.delay: No parent object provided, this can cause memory leaks");
        return null;
    }

    try {
        const timer = Qt.createQmlObject('import QtQuick; Timer { running: false }', parentObj);
        timer.interval = milliseconds;
        timer.repeat = false;
        timer.triggered.connect(function() {
            try {
                if (callbackFunc && typeof callbackFunc === "function") {
                    callbackFunc();
                }
            } catch (e) {
                console.error("Error in delay callback:", e);
            } finally {
                timer.destroy();
            }
        });
        timer.start();
        return timer;
    } catch (e) {
        console.error("Error creating timer:", e);
        return null;
    }
}


/**
 * Converts Arabic numbers to Roman numerals (1-20)
 * @param {number} number - Arabic number to convert
 * @returns {string} Roman numeral representation or empty string if out of range
 */
function arabicToRoman(number) {
    const romanNumerals = {
        1: 'I',
        2: 'II',
        3: 'III',
        4: 'IV',
        5: 'V',
        6: 'VI',
        7: 'VII',
        8: 'VIII',
        9: 'IX',
        10: 'X',
        11: 'XI',
        12: 'XII',
        13: 'XIII',
        14: 'XIV',
        15: 'XV',
        16: 'XVI',
        17: 'XVII',
        18: 'XVIII',
        19: 'XIX',
        20: 'XX'
    };

    return romanNumerals[number] || '';
}