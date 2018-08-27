module Triangle exposing (main)

{-
   Rotating triangle for introcom demo, the "hello world" of WebGL
-}

import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Html exposing (Html)
import Html.Attributes exposing (height, style, width)
import Json.Decode exposing (Value)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import WebGL exposing (Mesh, Shader)


main : Program Value Float Float
main =
    Browser.element
        { init = \_ -> ( 0, Cmd.none )
        , view = view
        , subscriptions = \_ -> onAnimationFrameDelta Basics.identity
        , update = \elapsed currentTime -> ( elapsed + currentTime, Cmd.none )
        }


view : Float -> Html msg
view t =
    WebGL.toHtml
        [ width 800
        , height 800
        , style "display" "block"
        , style "background-color" "#000"
        ]
        [ WebGL.entity
            vertexShader
            fragmentShader
            mesh
            { perspective = perspective (t / 1000)
            , time = t
            }
        , WebGL.entity
            littleMeshVertexShader
            fragmentShader
            littleMesh
            { perspective = perspective (t / 1000)
            , time = t
            }
        ]


perspective : Float -> Mat4
perspective t =
    Mat4.mul
        (Mat4.makePerspective 45 1 0.01 100)
        (Mat4.makeLookAt
            (vec3 (4 * cos t) 0 (4 * sin t))
            (vec3 0 0 0)
            (vec3 0 1 0)
        )



-- Mesh


type alias Vertex =
    { position : Vec3
    , color : Vec3
    }


mesh : Mesh Vertex
mesh =
    WebGL.triangles
        [ ( Vertex (vec3 0 0 0) (vec3 1 0 0)
          , Vertex (vec3 1 1 0) (vec3 0 1 0)
          , Vertex (vec3 1 -1 0) (vec3 0 0 1)
          )
        , ( Vertex (vec3 0 0 0) (vec3 1 0 0)
          , Vertex (vec3 -1 1 0) (vec3 0 1 0)
          , Vertex (vec3 -1 -1 0) (vec3 0 0 1)
          )
        ]


littleMesh : Mesh Vertex
littleMesh =
    WebGL.triangles
        [ ( Vertex (vec3 0 0 0) (vec3 1 0 0)
          , Vertex (vec3 0 0.5 0.5) (vec3 0 1 0)
          , Vertex (vec3 0 0.5 -0.5) (vec3 0 0 1)
          )
        , ( Vertex (vec3 0 1 0) (vec3 1 0 0)
          , Vertex (vec3 0 0.5 0.5) (vec3 0 1 0)
          , Vertex (vec3 0 0.5 -0.5) (vec3 0 0 1)
          )
        ]



-- Shaders


type alias Uniforms =
    { perspective : Mat4
    , time : Float
    }


vertexShader : Shader Vertex Uniforms { vcolor : Vec3 }
vertexShader =
    [glsl|

        attribute vec3 position;
        attribute vec3 color;
        uniform mat4 perspective;
        varying vec3 vcolor;

        void main () {
            gl_Position = perspective * vec4(position, 1.0);
            vcolor = color;
        }

    |]


littleMeshVertexShader : Shader Vertex Uniforms { vcolor : Vec3 }
littleMeshVertexShader =
    [glsl|

            attribute vec3 position;
            attribute vec3 color;
            uniform mat4 perspective;
            varying vec3 vcolor;

            precision mediump float;
            uniform float time;

            void main () {
                gl_Position =
                  perspective * vec4(
                    position.x,
                    position.y * sin(time/1000.),
                    position.z,
                    1.0
                  );
                vcolor = color;
            }

        |]


fragmentShader : Shader {} Uniforms { vcolor : Vec3 }
fragmentShader =
    [glsl|

        precision mediump float;
        varying vec3 vcolor;
        uniform float time;


        void main () {
            vec3 a = vec3(vcolor.x, vcolor.y, vcolor.z);

            a.y = abs(sin(time/900.)) * 0.3;
            a.z = abs(cos(time/1000.));

            gl_FragColor = vec4(a, 1.0);
        }

    |]
