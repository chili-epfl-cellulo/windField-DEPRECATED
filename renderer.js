Qt.include("three.js")

var camera, scene, renderer, gl;
var leaf, background, pressureField, pressurePoint;
var leafMaterial, backgroundMaterial, pressureFieldMaterial, pressurePointMaterial;

function initializeGL(canvas) {
    renderer = new THREE.Canvas3DRenderer(
                { canvas: canvas, antialias: true, devicePixelRatio: canvas.devicePixelRatio });
    renderer.setSize(canvas.width, canvas.height);
    gl = renderer.context;
    gl.enable(gl.BLEND)
    gl.blendEquation(gl.FUNC_ADD)
    gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA)

    initCamera();
    initScene();
}

/***INITIALIZATION HELPER METHODS***/
function initCamera() {
    console.log("Initialize Camera")
    camera = new THREE.OrthographicCamera(0, windField.robotMaxX, windField.robotMaxY, 0, 0.1, 5000);
    camera.position.z = windField.robotMaxY;
}

function initScene() {
    console.log("Initialize Scene")
    scene = new THREE.Scene();
    //Initialize geometries and materials/shaders
    var backgroundGeom = new THREE.PlaneGeometry(windField.robotMaxX, windField.robotMaxY, 1, 1)
    var pressureFieldGeom = new THREE.PlaneGeometry(windField.robotMaxX, windField.robotMaxY, 1, 1)
    var leafGeom = new THREE.SphereGeometry(windField.leafSize/2, 10, 10)
    initMaterials();

    //Create meshes and add them to the scene
    background = new THREE.Mesh(backgroundGeom, backgroundMaterial)
    background.position.x = windField.robotMaxX/2
    background.position.y = windField.robotMaxY/2
    pressureField = new THREE.Mesh(pressureFieldGeom, pressureFieldMaterial)
    pressureField.position.x = windField.robotMaxX/2
    pressureField.position.y = windField.robotMaxY/2
    pressureField.position.z = 200
    leaf = new THREE.Mesh(leafGeom, leafMaterial)
    leaf.position.z = 300

    //Add meshes to the scene
    background.renderOrder = 1;
    pressureField.renderOrder = 2;
    leaf.renderOrder = 3;
    scene.add(background);
    scene.add(pressureField);
    scene.add(leaf);

    //TODO: add pressureCellInput
    //      add force vectors
}

function initMaterials() {
    //Init shaders and textures

    //Background Material
    backgroundMaterial = new THREE.MeshBasicMaterial( { map: THREE.ImageUtils.loadTexture('assets/background.jpg')} );

    //Pressure Field Material
    var data = new Uint8Array(windField.numRows*windField.numCols*4);
    var index = 0
    for (var row = 0; row < windField.numRows; row++) {
        for (var col = 0; col < windField.numCols; col++) {
            if (!windField.pressureGrid[row][col][6]) {
                data[index] = 0
                data[index+1] = 0
                data[index+2] = 0
                data[index+3] = 255
            } else {
                var pressure = windField.pressureGrid[row][col][4];
                data[index] = pressure/100.0*255
                data[index+1] = 0
                data[index+2] = (100-pressure)/100.0*255
                data[index+3] = 255
            }
            index+=4
        }
    }
    var pressureFieldTexture = new THREE.DataTexture(data, windField.numCols, windField.numRows, THREE.RGBAFormat);
    pressureFieldTexture.needsUpdate = true
    pressureFieldMaterial = new THREE.MeshBasicMaterial({ map: pressureFieldTexture});

    //Leaf Material
    leafMaterial = new THREE.MeshBasicMaterial({ color: 0x00ff00,
                                                   ambient: 0x000000,
                                                   shading: THREE.SmoothShading });
}

function paintGL(canvas) {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.clearColor(1, 1, 1, 1);

    var sliderRatio = (sceneRotation.maximumValue-sceneRotation.value)/sceneRotation.maximumValue;
    camera.position.z = windField.robotMaxY*Math.cos(Math.PI/2*sliderRatio)
    camera.position.y = -windField.robotMaxY*Math.sin(Math.PI/2*sliderRatio)
    camera.lookAt(new THREE.Vector3(0,0,0))

    //Set leaf position
    leaf.position.x = windField.leafX;
    leaf.position.y = windField.robotMaxY - windField.leafY;

    pressureField.material.opacity = .75*Math.max(0.0, (sceneRotation.value - sceneRotation.maximumValue*.75)/(sceneRotation.maximumValue*.25));

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
