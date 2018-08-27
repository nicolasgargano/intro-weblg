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
import Math.Vector2 as Vec2 exposing (Vec2, vec2)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import Task
import WebGL exposing (Mesh, Shader)
import WebGL.Texture as Texture exposing (Error, Texture)


main : Program Value Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , subscriptions = \_ -> onAnimationFrameDelta Tick
        , update = update
        }


type Msg
    = Tick Float
    | TextureLoaded (Result Error Texture)


type alias Model =
    { time : Float
    , texture : Maybe Texture
    }


init : ( Model, Cmd Msg )
init =
    ( { time = 0.0, texture = Nothing }
    , Task.attempt TextureLoaded (Texture.load "texture/thwomp-face.jpg")
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick dt ->
            ( { model | time = model.time + dt }, Cmd.none )

        TextureLoaded textureResult ->
            ( { model | texture = Result.toMaybe textureResult }, Cmd.none )


view : Model -> Html msg
view model =
    WebGL.toHtml
        [ width 800
        , height 800
        , style "display" "block"
        , style "background-color" "#000"
        ]
        (case model.texture of
            Just tex ->
                [ WebGL.entity
                    vertexShader
                    fragmentShader
                    mesh
                    { perspective = perspective (model.time / 1000)
                    , time = model.time
                    , texture = tex
                    }
                , WebGL.entity
                    littleMeshVertexShader
                    littleMeshFragmentShader
                    littleMesh
                    { perspective = perspective (model.time / 1000)
                    , time = model.time
                    , texture = tex
                    }
                ]

            Nothing ->
                []
        )


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
    , coord : Vec2
    }


mesh : Mesh Vertex
mesh =
    WebGL.triangles
        [ ( Vertex (vec3 0 0 0) (vec3 1 0 0) (vec2 0 0)
          , Vertex (vec3 1 1 0) (vec3 0 1 0) (vec2 0 1)
          , Vertex (vec3 1 -1 0) (vec3 0 0 1) (vec2 1 1)
          )
        , ( Vertex (vec3 0 0 0) (vec3 1 0 0) (vec2 0 0)
          , Vertex (vec3 -1 1 0) (vec3 0 1 0) (vec2 1 0)
          , Vertex (vec3 -1 -1 0) (vec3 0 0 1) (vec2 1 1)
          )
        ]


littleMesh : Mesh Vertex
littleMesh =
    WebGL.triangles
        [ ( Vertex (vec3 0 0 0) (vec3 1 0 0) (vec2 0 0)
          , Vertex (vec3 0 0.5 0.5) (vec3 0 1 0) (vec2 0 1)
          , Vertex (vec3 0 0.5 -0.5) (vec3 0 0 1) (vec2 1 0)
          )
        , ( Vertex (vec3 0 1 0) (vec3 1 0 0) (vec2 0 0)
          , Vertex (vec3 0 0.5 0.5) (vec3 0 1 0) (vec2 0 1)
          , Vertex (vec3 0 0.5 -0.5) (vec3 0 0 1) (vec2 1 1)
          )
        ]



-- Shaders


type alias Uniforms =
    { perspective : Mat4
    , time : Float
    , texture : Texture
    }


vertexShader : Shader Vertex Uniforms { vcolor : Vec3, vcoord : Vec2 }
vertexShader =
    [glsl|
        attribute vec2 coord;
        attribute vec3 position;
        attribute vec3 color;

        uniform mat4 perspective;

        varying vec3 vcolor;
        varying vec2 vcoord;

        void main () {
            gl_Position = perspective * vec4(position, 1.0);
            vcolor = color;
            vcoord = coord;
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


fragmentShader : Shader {} Uniforms { vcolor : Vec3, vcoord : Vec2 }
fragmentShader =
    [glsl|

        precision mediump float;
        varying vec3 vcolor;
        uniform float time;
        uniform sampler2D texture;
        varying vec2 vcoord;


        void main () {
            vec3 a = vec3(vcolor.x, vcolor.y, vcolor.z);

            a.y = abs(sin(time/900.)) * 0.3;
            a.z = abs(cos(time/1000.));

            gl_FragColor = vec4(a, 1.0);
            gl_FragColor = texture2D(texture, vcoord) * vec4(a,1.0);
        }

    |]


littleMeshFragmentShader : Shader {} Uniforms { vcolor : Vec3 }
littleMeshFragmentShader =
    [glsl|

        precision mediump float;
        varying vec3 vcolor;
        uniform float time;


        void main () {
            vec3 a = vec3(vcolor.x, vcolor.y, vcolor.z);

            a.x = sin(time/450.);
            a.z = abs(sin(time/900.));

            gl_FragColor = vec4(a, 1.0);
        }

    |]
