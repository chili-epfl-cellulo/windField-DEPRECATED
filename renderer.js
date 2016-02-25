Qt.include("three.js")

var camera, scene, renderer, gl;
var leafObject, backgroundObject, pressureFieldObject;
var leafMaterial, backgroundMaterial, pressureFieldMaterial;

//var pressureInputs = [];
//var pressureInputMaterials = [];

function initializeGL(canvas, pressurefield, leaf) {
    renderer = new THREE.Canvas3DRenderer(
                { canvas: canvas, antialias: true, devicePixelRatio: canvas.devicePixelRatio });
    renderer.setSize(canvas.width, canvas.height);
    gl = renderer.context;
    //gl.enable(gl.BLEND)
    //gl.blendEquation(gl.FUNC_ADD)
    //gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA)

    initCamera(pressurefield);
    initScene(pressurefield, leaf);
}

/***INITIALIZATION HELPER METHODS***/
function initCamera(pressurefield) {
    console.log("Initialize Camera")
    camera = new THREE.OrthographicCamera(0, pressurefield.width, pressurefield.height, 0, 0.1, 5000);
    camera.position.z = pressurefield.height;
}

function initScene(pressurefield, leaf) {
    console.log("Initialize Scene")
    scene = new THREE.Scene();
    //Initialize geometries and materials/shaders
    var backgroundGeom = new THREE.PlaneGeometry(pressurefield.width, pressurefield.height, 1, 1)
    var pressureFieldGeom = new THREE.PlaneGeometry(pressurefield.width, pressurefield.height, 1, 1)
    var leafGeom = new THREE.SphereGeometry(leaf.leafSize/2, 10, 10)
    initMaterials(pressurefield, leaf);

    //Create meshes and add them to the scene
    backgroundObject = new THREE.Mesh(backgroundGeom, backgroundMaterial)
    backgroundObject.position.x = pressurefield.width/2
    backgroundObject.position.y = pressurefield.height/2
    pressureFieldObject = new THREE.Mesh(pressureFieldGeom, pressureFieldMaterial)
    pressureFieldObject.position.x = pressurefield.width/2
    pressureFieldObject.position.y = pressurefield.height/2
    pressureFieldObject.position.z = 200
    leafObject = new THREE.Mesh(leafGeom, leafMaterial)
    leafObject.position.z = 300

    //Add meshes to the scene
    backgroundObject.renderOrder = 1;
    pressureFieldObject.renderOrder = 2;
    leafObject.renderOrder = 3;
    scene.add(backgroundObject);
    scene.add(pressureFieldObject);
    scene.add(leafObject);
}

function initMaterials(pressurefield, leaf) {
    //Init shaders and textures

    //Background Material
    backgroundMaterial = new THREE.MeshBasicMaterial( { map: THREE.ImageUtils.loadTexture('assets/background.jpg')} );

    //Pressure Field Material
    var data = new Uint8Array(pressurefield.numRows*pressurefield.numCols*4);
    var index = 0
    for (var row = 0; row < pressurefield.numRows; row++) {
        for (var col = 0; col < pressurefield.numCols; col++) {
            if (!pressurefield.pressureGrid[row][col][6]) {
                data[index] = 0
                data[index+1] = 0
                data[index+2] = 0
                data[index+3] = 255
            } else {
                var pressure = pressurefield.pressureGrid[row][col][4];
                data[index] = pressure/100.0*255
                data[index+1] = 0
                data[index+2] = (100-pressure)/100.0*255
                data[index+3] = 255
            }
            index+=4
        }
    }
    var pressureFieldTexture = new THREE.DataTexture(data, pressurefield.numCols, pressurefield.numRows, THREE.RGBAFormat);
    pressureFieldTexture.needsUpdate = true
    pressureFieldMaterial = new THREE.MeshBasicMaterial({ map: pressureFieldTexture});

    //Leaf Material
    leafMaterial = new THREE.MeshBasicMaterial({ color: 0x00ff00,
                                                   ambient: 0x000000,
                                                   shading: THREE.SmoothShading });
}

function paintGL(pressurefield, leaf) {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.clearColor(1, 1, 1, 1);

    var sliderRatio = (controls.maxRotation-controls.rotation)/controls.maxRotation;
    camera.position.z = pressurefield.width*Math.cos(Math.PI/2*sliderRatio)
    camera.position.y = -pressurefield.height*Math.sin(Math.PI/2*sliderRatio)
    camera.lookAt(new THREE.Vector3(0,0,0))

    //Set leaf position
    leafObject.position.x = leaf.leafX;
    leafObject.position.y = leaf.robotMaxY - leaf.leafY;

    pressureFieldObject.material.opacity = .75*Math.max(0.0, (controls.rotation - controls.maximumRotation*.75)/(controls.maximumRotation*.25));
    //Render the scene
    renderer.render(scene, camera);
}

/*
function drawPressureCellInput(gl) {//use outlined cylinders
    //Draw outlines for existing pressure points
    for (var i = 0; i < maxPressurePointPairs*2; i++) {
        if (!pressurePoints[i])
            continue
        var row = pressurePoints[i].x
        var col = pressurePoints[i].y
        gl.lineWidth = 5
        if (i < maxPressurePointPairs)
            gl.strokeStyle = Qt.rgba(1,.5,0,1)
        else
            gl.strokeStyle = Qt.rgba(0,0,.5,1)
        gl.strokeRect(col*xGridSpacing,row*yGridSpacing,xGridSpacing,yGridSpacing)
    }

    //Draw the pressure cell selection outline rects
    for (var i = 0; i < pressureDragInput.length; i++) {
        if (!pressureDragInput[i])
            continue
        var row = pressureDragInput[i].x
        var col = pressureDragInput[i].y
        gl.lineWidth = 5
        if (i < maxPressurePointPairs)
            gl.strokeStyle = Qt.rgba(1,1,0,.75)
        else if (i >= maxPressurePointPairs)
            gl.strokeStyle = Qt.rgba(0,1,1,.75)
        gl.strokeRect(col*xGridSpacing,row*yGridSpacing,xGridSpacing,yGridSpacing)
    }
}

function drawPressureCellInput(gl) {//use outlined cylinders
    //Draw outlines for existing pressure points
    for (var i = 0; i < maxPressurePointPairs*2; i++) {
        if (!pressurePoints[i])
            continue
        var row = pressurePoints[i].x
        var col = pressurePoints[i].y
        gl.lineWidth = 5
        if (i < maxPressurePointPairs)
            gl.strokeStyle = Qt.rgba(1,.5,0,1)
        else
            gl.strokeStyle = Qt.rgba(0,0,.5,1)
        gl.strokeRect(col*xGridSpacing,row*yGridSpacing,xGridSpacing,yGridSpacing)
    }

    //Draw the pressure cell selection outline rects
    for (var i = 0; i < pressureDragInput.length; i++) {
        if (!pressureDragInput[i])
            continue
        var row = pressureDragInput[i].x
        var col = pressureDragInput[i].y
        gl.lineWidth = 5
        if (i < maxPressurePointPairs)
            gl.strokeStyle = Qt.rgba(1,1,0,.75)
        else if (i >= maxPressurePointPairs)
            gl.strokeStyle = Qt.rgba(0,1,1,.75)
        gl.strokeRect(col*xGridSpacing,row*yGridSpacing,xGridSpacing,yGridSpacing)
    }
}

//TODO: using particles would do the trick here
function drawPredictedPath(gl) {
    var origLeafX = leafX
    var origLeafY = leafY
    var origLeafXV = leafXV
    var origLeafYV = leafYV
    var origLeafXF = leafXF
    var origLeafYF = leafYF
    var origLeafXDrag = leafXFDrag
    var origLeafYDrag = leafYFDrag
    var origCollisionX = collisionForceX
    var origCollisionY = collisionForceY
    for (var i = 0; i < 1800; i++){
        updateLeaf()
        gl.fillStyle = Qt.rgba(1,1,1,1)
        gl.fillRect(leafX, leafY, 5, 5)
    }
    leafX = origLeafX
    leafY = origLeafY
    leafXV = origLeafXV
    leafYV = origLeafYV
    leafXF = origLeafXF
    leafYF = origLeafYF
    leafXFDrag = origLeafXDrag
    leafYFDrag = origLeafYDrag
    collisionForceX = origCollisionX
    collisionForceY = origCollisionY
}

//TODO: There is an ArrowHelper in Three.js for this
function drawLeafVectors(gl) {
    if (drawLeafVelocityVector) {
        // Draw velocity vector
        var vectorDrawX = leafXV*5
        var vectorDrawY = leafYV*5
        drawVector(gl, leafX, leafY, vectorDrawX, vectorDrawY, "white", 50.0/maxVelocity, leafSize, leafSize/2)
    }

    if (drawLeafForceVectors) {
        //Draw force vector
        vectorDrawX = 400*leafXF/maxForce
        vectorDrawY = 400*leafYF/maxForce
        drawVector(gl, leafX, leafY, vectorDrawX, vectorDrawY, "yellow", 1.0/maxForce, leafSize, leafSize/2)

        //Draw drag vector
        vectorDrawX = 400*leafXFDrag/maxForce
        vectorDrawY = 400*leafYFDrag/maxForce
        drawVector(gl, leafX, leafY, vectorDrawX, vectorDrawY, "red", 1.0/maxForce, leafSize, leafSize/2)
    }
}

function drawForceField(gl, gridDensity) {
    if (!drawForceGrid)
        return
    for (var row = Math.floor(gridDensity/2); row < numRows; row+=gridDensity) {
        for (var col = Math.floor(gridDensity/2); col < numCols; col+=gridDensity) {
            if (!pressureGrid[row][col][6])
                continue;

            var forceX = pressureGrid[row][col][2]
            var forceY = pressureGrid[row][col][3]

            var centerX = xGridSpacing/2+col*xGridSpacing;
            var centerY = yGridSpacing/2+row*yGridSpacing;

            var forceScaling = 50.0/maxForce
            var windVectorX = forceX*forceScaling
            var windVectorY = forceY*forceScaling

            drawVector(gl, centerX, centerY, windVectorX, windVectorY, Qt.rgba(0,0,0,1), 5.0/maxForce, 10.0 ,0)
        }
    }
}
*/
