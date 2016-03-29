import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

Item {
    width: 2560
    height: width * 10/16

    Rectangle{
     id: blackBg
     color:"#000000"
     anchors.fill: parent
     Image {
         id: background
         anchors.fill: parent
         source: "assets/start/AppTitle.png"
    }

    }

    property variant stateOrder:[   [start],
                                    [explanations],
                                    [game1Rules,game1Play],
                                    [game2Rules,game2Play],
                                    [game3Rules,game3Play],
                                    [goFurther],
                                    [finish]
                                ]


/*
    states:[
    State {
       name:"start"
       PropertyChanges {target:bgimage}
       StateChangeScript {
           name:"stateScriptStart"
           script:{
               picture.source=imagesList[0][2]
           }
       }
    },
    State {
            name:"state12"
            PropertyChanges {target:top1;color:"Azure"}
            StateChangeScript {
                name:"stateScript12"
              script:{
                  literal.text="Cupressaceae - State 12"
                  picture.source=imagesList[0][0]
              }
            }

        },
        State {
            name:"state13"
            PropertyChanges {target:top1;color:"WhiteSmoke"}
            StateChangeScript {
                name:"stateScript13"
              script:{
                literal.text="Cupressaceae - State 13"
                picture.source="kiparisi/piramidalen.jpg"
              }
            }

        },
 State {
         name:"state14"
         PropertyChanges {target:top1;color:"Linen"}
         StateChangeScript {
             name:"stateScript14"
           script:{
             literal.text="Cupressaceae - State 14"
             picture.source="kiparisi/tuya.jpg"
          }
         }
     },
 State {
         name:"state15"
         PropertyChanges {target:top1;color:"MistyRose"}
         StateChangeScript {
             name:"stateScript15"
           script:{
             literal.text="Cupressaceae - State 15"
             picture.source="kiparisi/septe.jpg"
           }
         }
     },
        State {
                name:"state2"
                PropertyChanges {target:top1;color:"Cornsilk"}
                StateChangeScript {
                    name:"stateScript2"
                  script:{
                    literal.text="Lakes - State2"
                    picture.source="ezera/osam.jpg"
                  }
                }
            },
        //States 3
        State {
           name:"state31"
           PropertyChanges {target:top1;color:"Cyan"}
           StateChangeScript {
               name:"stateScript31"
               script:{
                   literal.text="Rivers - State31"
                   picture.source="rivers/sea1.jpg"
               }
           }
        },
        State {
                name:"state32"
                PropertyChanges {target:top1;color:"LightCyan"}
                StateChangeScript {
                    name:"stateScript32"
                  script:{
                    literal.text="Rivers - State32"
                    picture.source="rivers/sea2.jpg"
                  }
                }
            },
        State {
                name:"state33"
                PropertyChanges {target:top1;color:"LightBlue"}
                StateChangeScript {
                    name:"stateScript33"
                  script:{
                    literal.text="Rivers - State33"
                    picture.source="rivers/sea3.jpg"
                  }
                }
            },
     State {
             name:"state34"
             PropertyChanges {target:top1;color:"LightSteelBlue"}
             StateChangeScript {
                 name:"stateScript34"
               script:{
                 literal.text="Rivers - State34"
                 picture.source="rivers/vodopad.jpg"
              }
             }
         },
     State {
             name:"state35"
             PropertyChanges {target:top1;color:"DeepSkyBlue"}
             StateChangeScript {
                 name:"stateScript35"
               script:{
                 literal.text="Rivers - State35"
                 picture.source="rivers/river.jpg"
               }
             }
         },
       State {
                    name:"state4"
                    PropertyChanges {target:top1;color:"LightGrey"}
                    StateChangeScript {
                        name:"stateScript4"
                      script:{
                        literal.text="Lakes - State4"
                        picture.source="ezera/vacha.jpg"
                      }
                    }
                },
        State {
           name:"state51"
           PropertyChanges {target:top1;color:"LightYellow"}
           StateChangeScript {
               name:"stateScript51"
               script:{
                   literal.text="Roses - State51"
                   picture.source="roses/buquet.jpg"
               }
           }
        },
        State {
                name:"state52"
                PropertyChanges {target:top1;color:"Gold"}
                StateChangeScript {
                    name:"stateScript52"
                  script:{
                    literal.text="Roses - State52"
                    picture.source="roses/bush.jpg"
                  }
                }

            },
            State {
                name:"state53"
                PropertyChanges {target:top1;color:"Khaki"}
                StateChangeScript {
                    name:"stateScript53"
                  script:{
                    literal.text="Roses - State53"
                    picture.source="roses/net.jpg"
                  }
                }
           },
     State {
             name:"state54"
             PropertyChanges {target:top1;color:"Moccasin"}
             StateChangeScript {
                 name:"stateScript54"
               script:{
                 literal.text="Roses - State54"
                 picture.source="roses/kalbo.jpg"
              }
             }
         },
     State {
             name:"state55"
             PropertyChanges {target:top1;color:"PeachPuff"}
             StateChangeScript {
                 name:"stateScript55"
               script:{
                 literal.text="Roses - State55"
                 picture.source="roses/katerach.jpg"
               }
             }
     }
  ]

*/

}

