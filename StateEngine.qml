import QtQuick 2.0

Item {
    property variant states: ['dummy']
    property int numStates: states.length
    property int currentStateIndex: 0
    property string currentState: states[currentStateIndex]

    function nextState(){
        currentStateIndex++;
        if(currentStateIndex >= states.length)
            currentStateIndex = states.length - 1;
    }

    function prevState(){
        currentStateIndex--;
        if(currentStateIndex < 0)
            currentStateIndex = 0;
    }

    function goToStateByName(stateName){
        var i = states.indexOf(stateName);
        console.log(i);
        if(i >= 0)
            currentStateIndex = i;
    }

    function goToStateByIndex(stateIndex){
        if(stateIndex >= 0 && stateIndex < numStates)
            currentStateIndex = stateIndex;
    }
}
