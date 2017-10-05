(* In order to map a functions to arguments inside held expression without evaluation *)
func/@Unevaluated/@Hold[arg1,arg2,arg3]
(* Hold[ func[Unevaluated@arg1],func[Unevaluated@arg2],func[Unevaluated@arg3] ] *)

(* if you want to prevent the function/arguments of a user-defined function from evaluating, we can create a temporary Holding
Function *)
Split[Hold[Print[1], Print[2 + 3], 0 + 1, 1 + 2, 2 + 3, 0*1, 1*2*3, 4^4],
Function[{e1,e2}, Head[Unevaluated@e1]===Head[Unevaluated@e2] ,HoldAll]]
(* Hold[Hold[Print[1], Print[2 + 3]], Hold[0 + 1, 1 + 2, 2 + 3], Hold[0 1, 2 3], Hold[4^4]] *)

Function[e, MemberQ[Unevaluated[e],0],HoldFirst]/@Unevaluated[{x*y,u*0*v,1*2*0}]
(* {False,True,True} *)

Map[Function[e, DeleteCases[Unevaluated[e],0],HoldFirst],
Unevaluated[{x*y,u*0*v,1*2*0}]
]
(* {x y, u v, 2} *)



(* Replace is one of the easiest methods for transforming a structure *)
Replace[Hold[1+2, Print[3,4], D[x^2,x]],
h_[elems___]:> {h,elems},{1}]
(* Hold[{Plus,1,2},{Print,3,4},{D,x^2,x}] *)

patts = Replace[Unevaluated[{1 + 2, Print[3, 4], D[x^2, x]}], h_[___] :> _h, {1}]
(* {_Plus, _Print, _D} *)

n = 79301169838123235887500;
held = Hold[Evaluate@FactorInteger[n]];
(* Hold[{{2,2},{3,3},{5,5},{7,7},{11,11}}] *)
Replace[held, {p_,a_}:> p^a,{2}]
(* Hold[{2^2,3^3,5^5,7^7,11^11}] *)
Replace[%, Hold[{elems___}]:>MakeBoxes[Times@elems,TraditionalForm]]
(* RowBox[{SuperscriptBox["2", "2"], " ", SuperscriptBox["3", "3"], " ", 
  SuperscriptBox["5", "5"], " ", SuperscriptBox["7", "7"], " ", 
  SuperscriptBox["11", "11"]}] *)
  DisplayForm[%]
 (* \!\(TagBox[RowBox[{SuperscriptBox["2", "2"], " ", SuperscriptBox["3", "3"], " ", 
SuperscriptBox["5", "5"], " ", SuperscriptBox["7", "7"], " ",SuperscriptBox["11", "11"]}], DisplayForm]\) *)



(* Function and With can stuff values into expression including held ones *)
With[{p = 2, a = 2, q = 5, b = 5},
 MakeBoxes[p^a*q^b] // DisplayForm
 ]
 (* \!\(TagBox[RowBox[{SuperscriptBox["2", "2"], " ", SuperscriptBox["5", "5"]}],DisplayForm]\) *)
 
 Function[{p, a, q, b}, DisplayForm@MakeBoxes[p^a*q^b]][2, 2, 5, 5]
 (* \!\(TagBox[RowBox[{SuperscriptBox["2", "2"], " ", SuperscriptBox["5", "5"]}],DisplayForm]\) *)
 
{a, b, c} = {1, 2, 3};
With[{a = a, b = b, c = c}, MakeBoxes[a^b + c*a] // DisplayForm]
(* \!\(TagBox[RowBox[{SuperscriptBox["1", "2"], "+", RowBox[{"3", " ", "1"}]}], DisplayForm]\) *)

(* With expressions can use SetDelayed for the initialization not to evaluate *)
{a, b, c} = {1, 2, 3};
With[{expr := a + b + c},
{expr, Length@Unevaluated[expr]}
]
(* {6,3} *)



(* Build up arguments inside of Hold and then apply function at the end *)
ClearAll[f];
SetAttributes[f, HoldAll];
f[iterand_, iterSpecs : {_Symbol, __} ..] := Module[{heldIterSpecs, heldVars, heldVarList},
  heldIterSpecs = Hold[iterSpecs];
  heldVars = Replace[heldIterSpecs, {s_Symbol, __} :> s, {1}];
  heldVarList  = Replace[heldVars, Hold[elems__] :> Hold[{elems}]];
  Block@@Append[heldVarList,
    Unevaluated[Integrate[iterand, iterSpecs]]
     ]
  ];
  {x, y, z} := {Print[1], Print[2], Print[3]};
  f[x^2 + y^2 + y^2, {x, -1, 1}, {y, -1, 1}, {z, -1, 1}]
  (* 8 *)
 
 

(* *)
Hold[Plus[##]]&[6, 7.5, 8 - 3 I, 4/5]
(* Hold[6 + 7.5 + (8 - 3 I) + 4/5] *)
Hold[Set[x,#]]&[77]
(* Hold[x = 77] *)
Composition[HoldForm, Plus] @@ {6, 7.5, 8 - 3 I, 4/5}
(* \!\(TagBox[RowBox[{"6", "+", "7.5`", " ", "+", RowBox[{"(", 
RowBox[{"8", "-", RowBox[{"3", " ", "I"}]}], ")"}], "+", FractionBox["4", "5"]}], HoldForm]\) *)
