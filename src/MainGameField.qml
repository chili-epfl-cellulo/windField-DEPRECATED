import QtQuick 2.0
import QtQuick.Window 2.0
import QtCanvas3D 1.0
import QtPositioning 5.2
import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.2
import QtQuick.Controls.Private 1.0
import QtQuick.Controls.Styles 1.3
import QtBluetooth 5.2
import Cellulo 1.0
import "renderer.js" as GLRender

Item{
    width: parent.width
    height: parent.height

    property variant robot: null
    property variant playground: playground
    property int fieldWidth: 2418
    property int fieldHeight: 950

    property alias windfield: windfield

    visible: false

    Canvas3D {
        id: windfield
        width: parent.width
        height: parent.height

        property int fieldWidth: 2418
        property int fieldHeight: 950

        property int robotMinX: (windfield.width - windfield.fieldWidth)/2
        property int robotMinY: (windfield.height - windfield.fieldHeight)/2
        property int robotMaxX: robotMinX + windfield.fieldWidth
        property int robotMaxY: robotMinY + windfield.fieldHeight

        //Game UI variables, kept here so that all components can have access to them
        property bool paused: true
        property bool drawPressureGrid: false
        property bool drawForceGrid: true
        property bool drawLeafVelocityVector: true
        property bool drawLeafForceVectors: true
        property bool drawPrediction: false
        property int currentAction: 0

        //Set the leaves here
        property variant leaves: [testLeaf]
        property int numLeaves: 1


        //Game Logic stuff
        property int nblifes: 3
        property int gameMode: 0
        property int bonus: 0

        // For Game 1
        property int nbOfHiddenPPoint:4
        property variant hiddenPPointList:[]
        property variant foundPPointList:[]
        property variant userPPoint: [ppoint1,ppoint2,ppoint3,ppoint4]
        property int sumDist: 0

        // Time management
        property double startTime: 0
        property double secondsElapsed: 0



        ////////////////////// FIELD RELATED FUNCTIONS
        function addPressurePoint(r,c,pressureLevel) {
            console.log('called here')
            pressurefield.addPressurePoint(r,c,pressureLevel)
        }

        function addPressurePointCoord(y,x,pressureLevel) {
            console.log('called here')
            var r = y
            var c = x
            pressurefield.addPressurePoint(r,c,pressureLevel)
        }



        function setInitialConfiguration(){
            switch (gameMode){
            case 1:
                setInitialConfigurationGame1()
            case 2:
                setInitialConfigurationGame2()
            }

        }

        function setInitialConfigurationGame1(){
            testLeaf.updateCellulo()
            testLeaf.leafXV = 0
            testLeaf.leafYV = 0
            testLeaf.leafMass = 2
            testLeaf.leafSize = 150
            testLeaf.leafXF = 0
            testLeaf.leafYF = 0
            testLeaf.leafXFDrag = 0
            testLeaf.leafYFDrag = 0
            testLeaf.collided = false
            testLeaf.resetRobotVelocity()
            pauseSimulation()
            windfield.state ="ready"
        }


        function setInitialConfigurationGame2(){
            setObstaclesfromZones()
            //Set test leaf info

            var startp = playground.zones[0]["path"]
            var center = getCenterFromPoly(startp)
            var startcoords = fromPointToCoords((center.x*fieldHeight-20)/pressurefield.numRows,(center.y*fieldWidth)/pressurefield.numCols)

            //var startcoords = fromPointToCoords((parent.robot.x*fieldHeight)/pressurefield.numRows,(parent.robot.t*fieldWidth)/pressurefield.numCols)
            console.log("startpoints")
            //startcoords =  Qt.point(50,50)
            console.log(startcoords.x, startcoords.y)
            testLeaf.leafX = startcoords.x
            testLeaf.leafY = startcoords.y
            testLeaf.leafXV = 0
            testLeaf.leafYV = 0
            testLeaf.leafMass = 2
            testLeaf.leafSize = 150
            testLeaf.leafXF = 0
            testLeaf.leafYF = 0
            testLeaf.leafXFDrag = 0
            testLeaf.leafYFDrag = 0
            testLeaf.collided = false
            //robot.coords.x = center.x
            //robot.coords.y = center.y
            //robot.setGobalPose(center.x, center.y, 0.0, 0.0, 0.0)
            pauseSimulation()
        }


        // - Set the obstales from the obstaclezone list of ZonesF
        function setObstaclesfromZones(){
            // TODO : PLACEMENT NOT ACCURATE OF THE ZONES
            //console.log("start zoning")
            var zones = playground.zones
            for (var i = 0; i < zones.length; i++) {

                if(zones[i]["name"].indexOf("obstacle")===0 ||zones[i]["name"].indexOf("cloud")===0){
                    console.log(zones[i]["name"])
                    var pathcoord = []
                    var minPX = pressurefield.numCols;var minPY = pressurefield.numRows;var maxPX = 0;var maxPY = 0;
                    for( var j =0 ; j< zones[i]["path"].length; j++){
                        var point  = zones[i]["path"][j]
                        var coord = fromPointToCoords(point.x,point.y)

                        minPX = Math.min(minPX,coord.x)
                        maxPX = Math.max(maxPX,coord.x)
                        minPY = Math.min(minPY,coord.y)
                        maxPY = Math.max(maxPY,coord.y)
                        pathcoord.push(Qt.point(coord.y,coord.x))
                        pressurefield.pressureGrid[coord.y][coord.x][6] = 0

                    }
                }
            }
        }

        function pauseSimulation() {
            paused = !paused;
        }




        ////////////////////// GAME LOGIC RELATED FUNCTIONS
        function checkPPoint(){
            console.log("start checking  ...")
            for(var hp = 0; hp < hiddenPPointList.length;hp++){
                var hpoint = hiddenPPointList[hp]
                console.log('hidden point at ', hiddenPPointList[hp])
                for(var up = 0; up < userPPoint.length;up++){
                    console.log('chekin point at ', userPPoint[up].row, userPPoint[up].col, userPPoint[up].ilevel)


                    if(hpoint[2]===userPPoint[up].ilevel && foundPPointList.indexOf(userPPoint[up])<0){ // check if pressure level is the same
                        var d = Math.sqrt((hpoint[0]-userPPoint[up].row)*(hpoint[0]-userPPoint[up].row) + (hpoint[1]-userPPoint[up].col)*(hpoint[1]-userPPoint[up].col))
                        console.log('distance of ', d)
                        sumDist+=d
                        console.log('total distance ', sumDist)
                        if(d < 10){
                            console.log( hiddenPPointList)
                            hiddenPPointList[hp][3]=false
                            foundPPointList.push(userPPoint[up])

                        }
                    }
                }
            }
            console.log('==========================')
            console.log(foundPPointList.length)
            showChecked()
            console.log('=====summmmm=====')
            console.log(1/sumDist)
            uicontrols.totalpoint  = sumDist
            if (foundPPointList.length < hiddenPPointList.length){
                windfield.state ="checked"
            }else{
                windfield.state ="win"
            }

        }

        function showChecked(){
            for(var up = 0; up < userPPoint.length;up++){
                if(foundPPointList.indexOf(userPPoint[up])>=0){
                    userPPoint[up].state="correct"
                }
                else{
                    userPPoint[up].state="incorrect"
                }
            }

        }

        function hidePressurePoint(){
            if(foundPPointList.length == hiddenPPointList.length){
                var nbLow = nbOfHiddenPPoint/2
                var row = 0
                var col = 0
                for(var i=0; i< nbLow; i++){
                    row = getRandomInt(0,pressurefield.numRows)
                    col = getRandomInt(0,pressurefield.numCols)
                    pressurefield.addPressurePointHidden(row,col,-3, false)
                    hiddenPPointList.push([row,col,-3, true])
                }
                for(var i=0; i< (nbOfHiddenPPoint- nbLow); i++){
                    row = getRandomInt(0,pressurefield.numRows)
                    col = getRandomInt(0,pressurefield.numCols)
                    pressurefield.addPressurePointHidden(row,col,3, false)
                    hiddenPPointList.push([row,col,3,true])
                }
            }else{
                for(var i=0; i< hiddenPPointList.length; i++){
                    if( hiddenPPointList[i][3]){
                        pressurefield.addPressurePointHidden(hiddenPPointList[i][0],hiddenPPointList[i][1],hiddenPPointList[i][2], false)
                    }
                    else{
                        pressurefield.removePressurePoint(hiddenPPointList[i][0],hiddenPPointList[i][1])
                    }
                }
            }
            console.log(hiddenPPointList)
            uicontrols.updateSimulation();
        }

        //resets the ppoint not found and disbale the other also disable the view of ppoint coorect set ppoint back to in play and call remove from game for the others
        function resetNotfoundPoint(){
            for(var i=0; i< userPPoint.length; i++){
                if( userPPoint[i].found){
                    userPPoint[i].putImageBack()
                    userPPoint[i].enabled= false
                    userPPoint[i].visible= false
                }
                else{
                    userPPoint[i].putImageBack()
                    userPPoint[i].state="inPlay"
                }
            }
        }

        function timeChanged(){
            if(!windfield.paused){
                if(startTime == 0)
                    startTime =  new Date().getTime()
                var currentTime = new Date().getTime()
                secondsElapsed = (currentTime-startTime)
            }else{
                startTime=secondsElapsed
            }
        }

        function setGameMode(){
            switch(gameMode){
            case 1:
                setInitialConfigurationGame1()
                leaves[0].resetRobotVelocity()
                leaves[0].tangible = false
                hidePressurePoint()
                windfield.drawPressureGrid = false
                //uicontrols.updateSimulation()
                uicontrols.enabled = true //TODO CHnage in false
                leaves[0].updateCellulo()
            case 2:
                setInitialConfigurationGame2()
            }
        }


        ////////////////////// UTILS FUNCTIONS
        // - return the center of a polygone
        function getCenterFromPoly(poly){
            var minx= poly[0].x, miny= poly[0].y, maxx = poly[0].x, maxy = poly[0].y;
            for(var i = 0 ; i <poly.length; i++){
                minx = Math.min(minx, poly[i].x);
                miny= Math.min(miny, poly[i].y);
                maxx= Math.max(maxx, poly[i].x);
                maxy= Math.max(maxy, poly[i].y);
                console.log(poly[i].x, poly[i].y)
            }
            console.log(maxy, miny ,maxx, minx)
            return Qt.point((maxx+minx)/2,(maxy+miny)/2)
        }

        // - return true if the point is in the polygone poly
        function isPointInPoly(poly, pt){
            for(var c = false, i = -1, l = poly.length, j = l - 1; ++i < l; j = i){
                //console.log(poly[i].x,poly[i].y )
                if(
                        ((poly[i].y <= pt.y && pt.y < poly[j].y) || (poly[j].y <= pt.y && pt.y < poly[i].y))
                        && (pt.x < (poly[j].x - poly[i].x) * (pt.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x)
                        && (c = !c));
                //console.log(c)
                return c;
            }
        }

        // - transform a point (between 0 and 1) to coordinates in the pressureGrid
        function fromPointToCoords(ptx,pty){
            return   Qt.point(Math.round(ptx*pressurefield.numCols),Math.round(pty*pressurefield.numRows));
        }

        function getRandomInt(min, max) {
            return Math.floor(Math.random() * (max - min)) + min;
        }

        ////////////////////// GL STUFFS
        onInitializeGL: {
            GLRender.initializeGL(windfield, pressurefield, leaves, numLeaves)
        }

        //Since we do no update the pressure grid while the simulation is running, the only thing we have to update then are the leaves
        onPaintGL: {
            if (!paused && gameMode!==1) {
                for (var i = 0; i < numLeaves; i++)
                    leaves[i].updateLeaf()
            }
            if (gameMode===1) {
                for (var i = 0; i < numLeaves; i++)
                    if(leaves[i].tangible){
                        leaves[i].updateLeaf()
                    }else{
                        leaves[i].updateCellulo()
                    }
            }
            GLRender.paintGL(pressurefield, leaves, numLeaves)
        }
        function setPressureFieldTextureDirty() {
            GLRender.pressureFieldUpdated = true;
        }

        Component.onCompleted: {
            pressurefield.resetwindfield()
        }

        onGameModeChanged: {
            setGameMode()
            console.log('game mode')
            console.log(gameMode)
        }



        ////////////////////// STATES
        states:[
            State{
                name: "lost"
                PropertyChanges {target: ontopPanel; state:"playagain"}
                PropertyChanges {target: ontopPanel; visible:true}
                PropertyChanges {target: windfield; startTime: 0}
                PropertyChanges {target: windfield; secondsElapsed: 0}
            },
            State{
                name: "over"
                PropertyChanges {target: ontopPanel; state:"gameover"}
                PropertyChanges {target: ontopPanel; visible:true}
                PropertyChanges {target: windfield; startTime: 0}
                PropertyChanges {target: windfield; secondsElapsed: 0}
            },
            State{
                name: "win"
                PropertyChanges {target: ontopPanel; state:"winr"}
                PropertyChanges {target: ontopPanel; visible:true}
                PropertyChanges {target: uicontrols; state:"bravo"}
                PropertyChanges {target: uicontrols; enabled:false}
            },
            State{
                name: "ready"
                PropertyChanges {target: ontopPanel; visible:false}
                PropertyChanges {target: uicontrols; state:"check"}
            },
            State{
                name: "waitconnect"
                PropertyChanges {target: ontopPanel; visible:true}
            },
            State{
                name: "checked" //game 1
                PropertyChanges {target: uicontrols; state:"playagain"}
            }
        ]



        ////////////////////// EMBEDDED ITEMS
        PressureField {
            width: windfield.fieldWidth
            height: windfield.fieldHeight
            x: windfield.robotMinX
            y: windfield.robotMinY
            id: pressurefield
        }

        Leaf {
            id: testLeaf
            field: pressurefield
            robot: parent.parent.robot
            allzones: playground
            currentZone: ''
            bonus:  0
            onBonusChanged:{
                console.log('the bonus is',bonus)
                uicontrols.totalpoint = bonus
            }
        }

        Timer {
            id:timer
            interval:30
            running: false; repeat: true
            onTriggered: windfield.timeChanged()
        }

    }

    ////////////////////// TOP PANEL
    UIPanel {
        //anchors.fill: parent
        id: uicontrols
        robot: parent.robot
        width: parent.width
        height: parent.height /5
        playground: playground
        startTime: startTime
        secondsElapsed: secondsElapsed
        totalpoint:0
    }


    Rectangle {
        id: ontopPanel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width/2
        height:  parent.height/2
        color: Qt.rgba(1,1,1,0.6)
        radius:110
        visible:false
        Text {
            id:thetext
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: button.top
            font.family: "Helvetica"
            font.pointSize: 20
            font.bold: true
            text:""
        }

        Item {
            id: button
            width: 100
            height: 100
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            Image {
                id: backgroundImage
                anchors.fill: parent
                source:  "../assets/buttons/reset.svg"
                MouseArea {
                    anchors.fill: backgroundImage
                    onClicked: { pressurefield.resetwindfield()
                        windfield.setInitialConfiguration()
                        windfield.setPressureFieldTextureDirty()
                        windfield.pauseSimulation()
                        windfield.state = "ready"
                    }

                }
            }
        }

        states:[
            State{
                name: "playagain"
                PropertyChanges {target: thetext; text:"Play again?"}
                PropertyChanges {target: backgroundImage; source:  "../assets/buttons/reset.svg"}
            },
            State{
                name: "winr"
                PropertyChanges {target: thetext; text:"You made it!"}
                PropertyChanges {target: backgroundImage; source:  "../assets/buttons/reset.svg"}
                //todo add time and total points
            },
            State{
                name: "wins"
                PropertyChanges {target: thetext; text:"You made it!"}
                PropertyChanges {target: backgroundImage; source:  "../assets/buttons/gameover.png"}
                //todo add time and total points
            },
            State{
                name: "gameover"
                PropertyChanges {target: thetext; text:"Game Over"}
                PropertyChanges {target: backgroundImage; source:  "../assets/buttons/gameover.png"}
            },
            State{
                name: "info"
                PropertyChanges {target: thetext; text:"Here some infos"}
                PropertyChanges {target: backgroundImage; source:  "../assets/buttons/info.png"}
            },
            State{
                name: "waiting"
                PropertyChanges {target: thetext; text:"Not Connected"}
                //PropertyChanges {target: backgroundImage; source:  "../assets/buttons/info.png"}
            }
        ]

    }

    ////////////////////// BOTTOM PANEL
    PressurePointPanel{
        id: pressurePointPanel

        DummyPressurePoint{
            ilevel: 3
            id:ppoint1
            onPutInGame: console.log("****1****putInGame****"+r+" "+c+" "+level)
            onUpdated: console.log("****1****updated****"+prevr+" "+prevc+" "+r+" "+c+" "+level)
            onRemovedFromGame: console.log("****1****removedFromGame****"+prevr+" "+prevc)
            initialImgX:0
        }

        DummyPressurePoint{
            ilevel: 3
            id:ppoint2
            onPutInGame: console.log("****2****putInGame****"+r+" "+c+" "+level)
            onUpdated: console.log("****2****updated****"+prevr+" "+prevc+" "+r+" "+c+" "+level)
            onRemovedFromGame: console.log("****2****removedFromGame****"+prevr+" "+prevc)
            initialImgX:ppoint1.initialImgX+20
        }

        DummyPressurePoint{
            ilevel: -3
            id:ppoint3
            onPutInGame: console.log("****3****putInGame****"+r+" "+c+" "+level)
            onUpdated: console.log("****3****updated****"+prevr+" "+prevc+" "+r+" "+c+" "+level)
            onRemovedFromGame: console.log("****3****removedFromGame****"+prevr+" "+prevc)
            initialImgX:ppoint2.initialImgX+20
        }

        DummyPressurePoint{
            ilevel: -3
            id:ppoint4
            onPutInGame: console.log("****4****putInGame****"+r+" "+c+" "+level)
            onUpdated: console.log("****4****updated****"+prevr+" "+prevc+" "+r+" "+c+" "+level)
            onRemovedFromGame: console.log("****4****removedFromGame****"+prevr+" "+prevc)
            initialImgX:ppoint3.initialImgX+20
        }


            }
            }

