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

    readonly property real startX: 95
    readonly property real startY: 960
    readonly property real startTheta: 90

    property variant robot: null
    property variant playground: playground
    property int fieldWidth: 2418
    property int fieldHeight: 950

    property alias windfield: windfield
    property alias mainGameFieldStateEngine: mainGameFieldStateEngine

    visible: false

    StateEngine{
        id: mainGameFieldStateEngine

        property bool canRun: currentState == 'ReadyToStart' || currentState == 'Running'
        property bool isRunning: currentState == 'Running'

        states: [
            'OutsideStartArea',
            'ReadyToStart',
            'Running',
            'CollidedWithWall',
            'Won'
        ]

        onCurrentStateChanged: {
            console.log("********* Game state changed: " + currentState + " ************")
            switch(currentState){
            case 'OutsideStartArea':
                cellulo1.robotComm.setGoalPose(startX, startY, startTheta, 150, 5);
                cellulo1.fullColor = "red";
                break;
            case 'ReadyToStart':
                cellulo1.fullColor = "green";
                break;
            case 'Running':
                cellulo1.fullColor = "white";
                break;
            case 'CollidedWithWall':

                //LIFE DECREMENT

                cellulo1.fullColor = "red";
                cellulo1.robotComm.setGoalVelocity(0,0,1);
                gameEndDialog.showCollided();
                break;
            case 'Won':

                //LIFE DECREMENT, SCORE DISPLAY

                cellulo1.pulse(Qt.rgba(0,1,0,1));
                cellulo1.robotComm.setGoalVelocity(0,0,1);
                gameEndDialog.showWon();
                break;
            default:
                break;
            }
        }

        function robotOnStart(){
            var xDiff = cellulo1.robotComm.x - startX;
            var yDiff = cellulo1.robotComm.y - startY;
            return Math.sqrt(xDiff*xDiff + yDiff*yDiff) < 20 && !cellulo1.robotComm.kidnapped;
        }

        Component.onCompleted: {
            cellulo1.robotComm.onPoseChanged.connect(cellulo1RobotCommPoseChanged);
            cellulo1.robotComm.onKidnappedChanged.connect(cellulo1RobotCommKidnappedChanged);
            gameEndDialog.resetClicked.connect(gameEndDialogresetClicked);
            theLeaf.won.connect(leafWon);
            theLeaf.collidedWithWall(leafCollidedWithWall);
        }

        function cellulo1RobotCommPoseChanged() {
            switch(currentState){
            case 'OutsideStartArea':
                if(robotOnStart())
                    goToStateByName('ReadyToStart');
                break;
            case 'ReadyToStart':
                if(!robotOnStart())
                    goToStateByName('OutsideStartArea');
                break;
            case 'Running':

                break;
            case 'CollidedWithWall':

                break;
            case 'Won':

                break;
            default:
                break;
            }
        }

        function cellulo1RobotCommKidnappedChanged() {
            switch(currentState){
            case 'OutsideStartArea':
                break;
            case 'ReadyToStart':
                if(cellulo1.robotComm.kidnapped)
                    goToStateByName('OutsideStartArea');
                break;
            case 'Running':

                break;
            case 'CollidedWithWall':

                break;
            case 'Won':

                break;
            default:
                break;
            }
        }

        function leafCollidedWithWall() {
            goToStateByName('CollidedWithWall');
        }

        function leafWon() {
            goToStateByName('Won');
        }

        function gameEndDialogresetClicked() {
            if(robotOnStart())
                goToStateByName('ReadyToStart');
            else
                goToStateByName('OutsideStartArea');
        }
    }

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
        property variant leaves: [theLeaf]
        property int numLeaves: 1


        //Game Logic stuff
        property int nblifes: 3
        property int gameMode: 2
        property int bonus: 0

        // For Game 1
        property int nbOfHiddenPPoint:4

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
            //setObstaclesfromZones()
            //Set test leaf info

            var startp = playground.zones[0]["path"]
            var center = getCenterFromPoly(startp)
            var startcoords = fromPointToCoords((parent.robot.x*fieldHeight)/pressurefield.numRows,(parent.robot.t*fieldWidth)/pressurefield.numCols)
            console.log("startpoints")
            //startcoords =  Qt.point(50,50)
            console.log(startcoords.x, startcoords.y)
            theLeaf.leafX = startcoords.x
            theLeaf.leafY = startcoords.y
            theLeaf.leafXV = 0
            theLeaf.leafYV = 0
            //theLeaf.leafMass = 2
            theLeaf.leafSize = 150
            theLeaf.leafXF = 0
            theLeaf.leafYF = 0
            theLeaf.leafXFDrag = 0
            theLeaf.leafYFDrag = 0
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
            theLeaf.leafX = startcoords.x
            theLeaf.leafY = startcoords.y
            theLeaf.leafXV = 0
            theLeaf.leafYV = 0
            //theLeaf.leafMass = 2
            theLeaf.leafSize = 150
            theLeaf.leafXF = 0
            theLeaf.leafYF = 0
            theLeaf.leafXFDrag = 0
            theLeaf.leafYFDrag = 0
            //robot.coords.x = center.x
            //robot.coords.y = center.y
            //robot.setGobalPose(center.x, center.y, 0.0, 0.0, 0.0)
        }

        // - Set obstacle spots
        function setObstacles() {
            pressurefield.pressureGrid[10][30][6] = 0
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
                    // - try to fill the zone with obstacle
                    // TODO : NOT COVERING THE WHOLE ZONE
                    /*for (var px = minPX ; px<maxPX; px++){
                        for (var py = minPY ; py<maxPY ; py++){
                            if(isPointInPoly(pathcoord, Qt.point(py,px)))
                                pressurefield.pressureGrid[py][px][6] = 0
                        }
                    }*/
                }
            }
        }

        function hidePressurePoint(){
            var nbLow = nbOfHiddenPPoint/2

            pressurefield.addPressurePointHidden(50,15,-3,false) //todo remove this test
            pressurefield.addPressurePointHidden(50,15,-3,true) //todo remove this test
            for(var i=0; i< nbLow; i++){
                pressurefield.addPressurePointHidden(getRandomInt(0,pressurefield.numRows),getRandomInt(0,pressurefield.numCols),-3, false)
            }
            for(var i=0; i< (nbOfHiddenPPoint- nbLow); i++){
                pressurefield.addPressurePointHidden(getRandomInt(0,pressurefield.numRows),getRandomInt(0,pressurefield.numCols),3, false)
            }
        }

        ////////////////////// GAME LOGIC RELATED FUNCTIONS
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
                leaves[0].tangible = true
                hidePressurePoint()
                windfield.drawPressureGrid = false
                uicontrols.updateSimulation()
                uicontrols.enabled = true //TODO CHnage in false
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
            for (var i = 0; i < numLeaves; i++)
                leaves[i].updateLeaf()

            if (gameMode===1) {
                for (var i = 0; i < numLeaves; i++)
                    if(leaves[i].tangible){
                        console.log("uuuuuuuuuuuuuuuuuuuuuuuuuuuuu")
                        leaves[i].updateLeaf()
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

        ////////////////////// EMBEDDED ITEMS
        PressureField {
            width: windfield.fieldWidth
            height: windfield.fieldHeight
            x: windfield.robotMinX
            y: windfield.robotMinY
            id: pressurefield
        }

        Leaf {
            id: theLeaf
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

    ////////////////////// BOTTOM PANEL
    PressurePointPanel{
        id: pressurePointPanel

        PressurePoint{
            ilevel: 3

            onPutInGame: console.log("****1****putInGame****"+r+" "+c+" "+level)
            onUpdated: console.log("****1****updated****"+prevr+" "+prevc+" "+r+" "+c+" "+level)
            onRemovedFromGame: console.log("****1****removedFromGame****"+prevr+" "+prevc)
        }

        PressurePoint{
            ilevel: 3

            onPutInGame: console.log("****2****putInGame****"+r+" "+c+" "+level)
            onUpdated: console.log("****2****updated****"+prevr+" "+prevc+" "+r+" "+c+" "+level)
            onRemovedFromGame: console.log("****2****removedFromGame****"+prevr+" "+prevc)
        }

        PressurePoint{
            ilevel: -3

            onPutInGame: console.log("****3****putInGame****"+r+" "+c+" "+level)
            onUpdated: console.log("****3****updated****"+prevr+" "+prevc+" "+r+" "+c+" "+level)
            onRemovedFromGame: console.log("****3****removedFromGame****"+prevr+" "+prevc)
        }

        PressurePoint{
            ilevel: -3

            onPutInGame: console.log("****4****putInGame****"+r+" "+c+" "+level)
            onUpdated: console.log("****4****updated****"+prevr+" "+prevc+" "+r+" "+c+" "+level)
            onRemovedFromGame: console.log("****4****removedFromGame****"+prevr+" "+prevc)
        }
    }
}

