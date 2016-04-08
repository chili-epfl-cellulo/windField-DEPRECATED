Qt.include("three.js")

var camera, scene, renderer, gl;
var backgroundObject, pressureFieldObject;
var backgroundMaterial, pressureFieldMaterial;

var leafObjects = [];
var leafMaterials = [];

var pressureInputCellObjects = [];
var pressureInputCellMaterials = [];

var pressureFieldUpdated = false;


var opa_val = 0.4;


//Vectors
var leafForceVectors = [];
var leafVelocityVectors = [];
var leafDragVectors = [];

function initializeGL(canvas, pressurefield, leaves, numLeaves) {
    renderer = new THREE.Canvas3DRenderer(
                { canvas: canvas, antialias: true, devicePixelRatio: canvas.devicePixelRatio });
    renderer.setSize(canvas.width, canvas.height);
    gl = renderer.context;
    initCamera(pressurefield);
    initScene(pressurefield, leaves, numLeaves);
}

/***INITIALIZATION HELPER METHODS***/
function initCamera(pressurefield) {
    console.log("Initialize Camera")
    camera = new THREE.OrthographicCamera(0, windField.width, windField.height, 0, 0.1, 5000);
    camera.position.z = pressurefield.height;
}

function initScene(pressurefield, leaves, numLeaves) {
    console.log("Initialize Scene")
    scene = new THREE.Scene();
    //Initialize geometries and materials/shaders
    var backgroundGeom = new THREE.PlaneBufferGeometry(windField.width, windField.height, 1, 1)
    var pressureFieldGeom = new THREE.PlaneBufferGeometry(pressurefield.width, pressurefield.height, 1, 1)
    var leafGeom;
    if (numLeaves)
        //leafGeom = new THREE.PlaneBufferGeometry(leaves[0].leafSize/2,leaves[0].leafSize/2, 1, 1)
        leafGeom =  new THREE.CircleGeometry(leaves[0].leafSize/2, 20)
    var pressureInputCellGeom = new THREE.PlaneBufferGeometry(pressurefield.xGridSpacing, pressurefield.yGridSpacing, 1, 1)
    initMaterials(pressurefield, leaves, numLeaves);

    //Create meshes and add them to the scene
    backgroundObject = new THREE.Mesh(backgroundGeom, backgroundMaterial)
    backgroundObject.position.x = windField.width/2
    backgroundObject.position.y = windField.height/2
    pressureFieldObject = new THREE.Mesh(pressureFieldGeom, pressureFieldMaterial)
    pressureFieldObject.position.x = pressurefield.width/2 + windField.robotMinX
    pressureFieldObject.position.y = pressurefield.height/2 + windField.robotMinY
    pressureFieldObject.position.z = 200

    for (var i = 0; i < numLeaves; i++) {
        leafObjects[i] = new THREE.Mesh( leafGeom, leafMaterials[i])
        leafObjects[i].position.z = 300
        leafObjects[i].renderOrder = 5;
        scene.add(leafObjects[i]);

        //Vectors: just initialize arrows for now, updating from leaf info happens on paint
        var dir = new THREE.Vector3( 1, 0, 0 );
        var origin = new THREE.Vector3( 0, 0, 0 );
        var length = 4;
        //var linemat =  new THREE.LineBasicMaterial({linewidth : 3});

        leafForceVectors[i] = new THREE.ArrowHelper( dir, origin, length, 0xFF000);
        //leafForceVectors.line.material = linemat
        leafDragVectors[i] = new THREE.ArrowHelper( dir, origin, length, 0x0099FF);
        //leafDragVectors.line.material = linemat
        leafVelocityVectors[i] = new THREE.ArrowHelper( dir, origin, length, 0x66CC00);
        //leafVelocityVectors.line.material = linemat
        scene.add(leafForceVectors[i])
        scene.add(leafDragVectors[i])
        scene.add(leafVelocityVectors[i])
    }

    for (var i = 0; i < pressurefield.maxPressurePoints; i++) {
        pressureInputCellObjects[i] = new THREE.Mesh(pressureInputCellGeom, pressureInputCellMaterials[i])
        pressureInputCellObjects[i].position.z = 250
        pressureInputCellObjects[i].renderOrder = 2
        scene.add(pressureInputCellObjects[i])
    }

    //Add meshes to the scene
    backgroundObject.renderOrder = 1;
    pressureFieldObject.renderOrder = 4;
    scene.add(backgroundObject);
    scene.add(pressureFieldObject);
}

function initMaterials(pressurefield, leaves, numLeaves) {
    //Init shaders and textures

    //Background Material
    var bgtexture =  THREE.ImageUtils.loadTexture('assets/test.png')
    bgtexture.minFilter = THREE.LinearFilter; //THREE.NearestFilter;
    backgroundMaterial = new THREE.MeshBasicMaterial( { map:bgtexture} );

    createPressureFieldMaterial()

    //Leaf Material - may want to change material based on leaf properties
    for (var i = 0; i < numLeaves; i++) {
        var leaftexture =  THREE.ImageUtils.loadTexture('assets/cellulo_balloon.png')
        leaftexture.minFilter = THREE.LinearFilter; //THREE.NearestFilter;
       leafMaterials[i]  = new THREE.MeshBasicMaterial( { map:leaftexture ,transparent: true, opacity: 0.9});

        }

    for (var i = 0; i < pressurefield.maxPressurePoints; i++) {
        pressureInputCellMaterials[i] = new THREE.MeshBasicMaterial({ color: Qt.rgba(1.0, 1.0, 1.0, 1.0),
                                                                     ambient: 0x000000,
                                                                     shading: THREE.SmoothShading})
         //pressureInputCellMaterials[i] = new THREE.MeshBasicMaterial( { map: THREE.ImageUtils.loadTexture('assets/highPressure.png')} );
    }
}

function createPressureFieldMaterial() {
    //Pressure Field Material
    var data = new Uint8Array(pressurefield.numRows*pressurefield.numCols*4);
    var index = 0
    for (var row = 0; row < pressurefield.numRows; row++) {
        for (var col = 0; col < pressurefield.numCols; col++) {
            if (!pressurefield.pressureGrid[row][col][6]) {
                data[index] = 0
                data[index+1] = 0
                data[index+2] = 0
                data[index+3] = 125
            } else {
                var pressure = pressurefield.pressureGrid[row][col][4];
                //data[index] = pressure/100.0*255
                //data[index+1] = 0
                //data[index+2] = (100-pressure)/100.0*255
                //data[index+3] = 255

                var rgba = getRGBA(pressure/100);
                data[index] =  rgba.r*255;
                data[index+1] = rgba.g*255;
                data[index+2] = rgba.b*255;
                data[index+3] = 255;
            }
            index+=4
        }
    }
    var pressureFieldTexture = new THREE.DataTexture(data, pressurefield.numCols, pressurefield.numRows, THREE.RGBAFormat);
    //pressureFieldTexture.minFIlter = THREE.LinearFilter;
    pressureFieldTexture.needsUpdate = true
    pressureFieldTexture.minFilter = THREE.NearestFilter
    pressureFieldMaterial = new THREE.MeshBasicMaterial({ map: pressureFieldTexture, transparent:true, opacity: opa_val, depthWrite: false});
    pressureFieldUpdated = false
}

function getRGBA(intensity){
    var c7 = new THREE.Color(1,0,0);
    var c6 = new THREE.Color(1, 0.3, 0)
    var c5 = new THREE.Color(1, 0.5, 0)
    var c4 = new THREE.Color(1, 1, 1.0)
    var c3=  new THREE.Color(0, 0.5, 1)
    var c2 = new THREE.Color(0, 0.3, 1)
    var c1 = new THREE.Color(0, 0, 1)
    var colorRamp = [c1,c2,c3,c4,c5,c6,c7]
    /*if(intensity<=0.33)
        return c4.lerp(c1,intensity)
    else if(intensity>=0.66)
        return c7.lerp(c4,intensity)
    else
        return c4;*/
    if(intensity<1/7){
        return c1;
    }else if(intensity<2/7){
        return c1.lerp(c2,intensity);
    }else if(intensity<3/7){
        return c2.lerp(c3,intensity);
    } else if(intensity<4/7){
        return c3.lerp(c4,intensity);
    }else if(intensity<5/7){
       return c4.lerp(c5,intensity);
    }else if(intensity<6/7){
       return c5.lerp(c6,intensity);
    }else{
        return c6.lerp(c7,intensity);
    }
}



  /**
   * Calculate the position of an object after a period of time.
   *
   * p = p0 + vt + at^2
   *
   * @param  {object|Point}  p    {x,y} initial position
   * @param  {EFH.Vector}    v    velocity vector
   * @param  {EFH.Vector}    a    acceleration vector
   * @param  {Number}        t    time in seconds
   * @return {object}             {x, y} final position
   */
  function calcPosition(p, v, a, t) {
    return {
      x : p.x + (v.xComponent() * t + a.xComponent() * (t*t)),
      y : p.y + (v.yComponent() * t + a.yComponent() * (t*t))
    }
  }


  /**
   * Calculates the velocity of an object after a period of time
   *
   * v = v0 + at
   *
   * @param  {EFH.Vector}   v    initial velocity Vector
   * @param  {EFH.Vector}   a    acceleration vector
   * @param  {Number}       t    time passed in seconds
   * @return {EFH.Vector}        final velocity vector
   */
  function calcVelocity(v, a, t) {
    return v.add( a.mult(t) );
  }



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


function paintGL(pressurefield, leaves, numLeaves) {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.clearColor(1, 1, 1, 1);

    camera.position.z = 1000;
    camera.position.y = 0;
    camera.lookAt(new THREE.Vector3(0,0,0))

    //Set leaf position
    for (var i = 0; i < numLeaves; i++) {
        leafObjects[i].position.x = leaves[i].leafX + windField.robotMinX;
        leafObjects[i].position.y = windField.height - leaves[i].leafY - windField.robotMinY;
        if (leaves[i].collided) {
            leafObjects[i].material.color = Qt.rgba(0.5,0.5,0.5,0.5);
            leafObjects[i].material.needsUpdate = true;
        } else {
            leafObjects[i].material.color = Qt.rgba(1,1,1,1);
            leafObjects[i].material.needsUpdate = true;
        }

        var leafDragDirection = new THREE.Vector3(leaves[i].leafXFDrag, -leaves[i].leafYFDrag, 0);
        var dragLength = leafDragDirection.length()
        if (dragLength) {
            leafDragVectors[i].setDirection(leafDragDirection.normalize());
            leafDragVectors[i].position.x = leafObjects[i].position.x;
            leafDragVectors[i].position.y = leafObjects[i].position.y;
            leafDragVectors[i].position.z = leafObjects[i].position.z;
            leafDragVectors[i].setLength(leafDragDirection.length()*1000/pressurefield.maxForce);
        }

        var leafForceDirection = new THREE.Vector3(leaves[i].leafXF, -leaves[i].leafYF, 0);
        var forceLength = leafForceDirection.length()
        if (forceLength) {
            leafForceVectors[i].setDirection(leafForceDirection.normalize());
            leafForceVectors[i].position.x = leafObjects[i].position.x;
            leafForceVectors[i].position.y = leafObjects[i].position.y;
            leafForceVectors[i].position.z = leafObjects[i].position.z;
            leafForceVectors[i].setLength(leafForceDirection.length()*1000/pressurefield.maxForce);
        }

        var leafVelocityDirection = new THREE.Vector3(leaves[i].leafXV, -leaves[i].leafYV, 0);
        var velocityLength = leafVelocityDirection.length()
        if (velocityLength) {
            leafVelocityVectors[i].setDirection(leafVelocityDirection.normalize());
            leafVelocityVectors[i].position.x = leafObjects[i].position.x;
            leafVelocityVectors[i].position.y = leafObjects[i].position.y;
            leafVelocityVectors[i].position.z = leafObjects[i].position.z;
            leafVelocityVectors[i].setLength(leafVelocityDirection.length()*100);
        }

        leafDragVectors[i].visible = windField.drawLeafForceVectors && (dragLength > 0);
        leafForceVectors[i].visible = windField.drawLeafForceVectors && (forceLength > 0);
        leafVelocityVectors[i].visible = windField.drawLeafVelocityVector && (velocityLength > 0);
    }

    //Update pressurefield texture as necessary given new pressurefield values
    if (pressureFieldUpdated) {
        createPressureFieldMaterial()
        pressureFieldObject.material = pressureFieldMaterial;
    }

    pressureFieldObject.material.visible = windField.drawPressureGrid;
    pressureFieldObject.material.needsUpdate = true;

    for (var i = 0; i < pressurefield.maxPressurePoints; i++) {
        pressureInputCellObjects[i].material.visible = (pressurefield.pressurePoints[i].state > pressurefield.inactive);
        if (pressurefield.pressurePoints[i].state == pressurefield.inactive)
            continue;
        var pressureSgn = pressurefield.pressurePoints[i].strength > 50.0 ? 1 : -1
        var pressureColorLevel = Math.log(Math.abs(50.0-pressurefield.pressurePoints[i].strength))*3.0/Math.log(50.0);
        var red;
        var blue;
        if (pressureSgn == -1) {
            red = 0;
            blue = pressureColorLevel/3.0;
        } else {
            blue = 0;
            red = pressureColorLevel/3.0;
        }

        pressureInputCellObjects[i].material.color = Qt.rgba(red, 0.0, blue, 1.0);
        pressureInputCellObjects[i].material.needsUpdate = true
        var xGridSpacing = pressurefield.xGridSpacing;
        var yGridSpacing = pressurefield.yGridSpacing;
        var curRow = Math.floor(pressurefield.pressurePoints[i].position.y/yGridSpacing);
        var curCol = Math.floor(pressurefield.pressurePoints[i].position.x/xGridSpacing);
        pressureInputCellObjects[i].position.x = curCol*xGridSpacing+xGridSpacing/2.0 + windField.robotMinX;
        pressureInputCellObjects[i].position.y = (pressurefield.numRows - curRow)*yGridSpacing-yGridSpacing/2 + windField.robotMinY;
    }

    //Render the scene
    renderer.render(scene, camera);
}

/*
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
