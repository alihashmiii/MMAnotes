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
 
 

(* Construct a held result from parts. the arguments will evaluate but the final expression produced is held *)
Hold[Plus[##]]&[6, 7.5, 8 - 3 I, 4/5]
(* Hold[6 + 7.5 + (8 - 3 I) + 4/5] *)
Hold[Set[x,#]]&[77]
(* Hold[x = 77] *)
Composition[HoldForm, Plus] @@ {6, 7.5, 8 - 3 I, 4/5}
(* \!\(TagBox[RowBox[{"6", "+", "7.5`", " ", "+", RowBox[{"(", 
RowBox[{"8", "-", RowBox[{"3", " ", "I"}]}], ")"}], "+", FractionBox["4", "5"]}], HoldForm]\) *)



(* Wrap everything in a holding wrapper, do manipulations and then use ReleaseHold *)
atomsHeld = Map[HoldForm, Unevaluated[2^1*3^2*5^3], {-1}, Heads -> True]
(* Times[Power[2,1],Power[3,2],Power[5,3]] *)
atomsInvertHead = Thread[atomsHeld, HoldForm[Power]]
(* Power[Times[2,1],Times[3,2],Times[5,3]] *)
atomsChangeHead = atomsInvertHead/.HoldForm[Power]-> HoldForm@Plus
(* Plus[Times[2,1],Times[3,2],Times[5,3]] *)
ReleaseHold[atomsChangeHead]
(* 36 *)

(* A typesetting form that does the same job as above (HoldForm is invisible but boxes around held expressions are visible) *)
SetAttributes[HoldFormFrame,HoldAll];
HoldFormFrame/: MakeBoxes[HoldFormFrame[expr_],fmt_]:= TagBox[FrameBox@MakeBoxes[expr,fmt],HoldFormFrame];
atomsHeld = Map[HoldFormFrame, Unevaluated[2^1*3^2*5^3],{-1}, Heads -> True];
Thread[atomsHeld, HoldFormFrame[Power]]/.HoldFormFrame[Power] -> HoldFormFrame[Plus]//DeleteCases[#, HoldFormFrame,{-1},Heads->True]&
(* 36 *)



(* Replace function names with temporary dummy symbols *)
(* taking similar example above *)
atomsHeld = Unevaluated[2^1*3^2*5^3]/. {Power -> MyPower, Times -> MyTimes}
(*MyTimes[MyPower[2, 1], MyPower[3, 2], MyPower[5, 3]] *)
Thread[atomsHeld, MyPower]
(* MyPower[MyTimes[2, 3, 5], MyTimes[1, 2, 3]] *)
% /. MyPower -> MyPlus
(* MyPlus[MyTimes[2, 3, 5], MyTimes[1, 2, 3]] *)
% /. {MyPlus -> Plus, MyTimes -> Times}
(* 36 *)

(* a more subtle way to do this using Block or Module *)
Block[{Power,Times},
Thread[2^1*3^2*5^3, Power] /. Power -> Plus
]
(* 36 *)
Module[{Power,Plus,Times,thread,plus,expr},
Print[Power," ",Times," ",Plus];
expr = 2^1*3^2*5^3;
thread = Thread[expr, Power];
plus = thread /. Power -> Plus;
plus/. {Plus -> Symbol["Plus"], Times -> Symbol["Times"]}
]
(* Power$9174 Plus$9174 Times$9174 *)
(* 36 *)

(* if we do not want to manually enter Symbol["Plus"] ... Symbol["Times"] ourself. we can do the following *)
UndoModuloLocals[sampleSym_Symbol]:= Module[{sampleName,suffix,suffixLen,nameForm},
sampleName = SymbolName@Unevaluated[sampleSym];
suffix = StringTake[sampleName, {StringPosition[sampleName, "$"][[-1,1]],-1}];
suffixLen = StringLength@suffix;
nameForm = "*" <> suffix;
s_Symbol :> With[{str = SymbolName@Unevaluated[s]},
Symbol@StringDrop[str,-suffixLen]/;StringMatchQ[str,nameForm]
]
];

Module[{Power, Plus, Times, thread, plus, expr, sampleSym},
 expr = 2^1*3^2*5^3;
 thread = Thread[expr, Power];
 plus = thread /. Power -> Plus;
 plus /. UndoModuloLocals[sampleSym]
 ]
 (* 36 *)



(* Block to temporarily nullify built-in or user-defined functions *)
Block[{Integrate, int, y, exp},
 int = Integrate[(x + y)^3, x];
 exp = Map[Expand, int, 1];
 Print[exp];
 exp
 ]
 (* Integrate[x^3+3 x^2 y+3 x y^2+y^3,x] *)
 (* x^4/4 + x^3 y + (3 x^2 y^2)/2 + x y^3 *)



(* ParsedForm: to check the FullForm of an expression before the argument evaluates  *)
Attributes[ParsedForm] = HoldAll;
Format[ParsedForm[expr_]] := HoldForm[FullForm@expr];
ParsedForm[Tan[5.] Sin[6. Pi]]
(* \!\(TagBox[TagBox[StyleBox[RowBox[{"Times", "[",RowBox[{RowBox[{"Tan", "[", "5.`", "]"}], ",", RowBox[{"Sin", "[",
RowBox[{"Times", "[", RowBox[{"6.`", ",", "Pi"}], "]"}], "]"}]}], "]"}], ShowSpecialCharacters->False,ShowStringCharacters->True,
NumberMarks->True],FullForm], HoldForm]\) *)



(* we can use HoldForm to see how automatic renaming of the inner construct's local variables may occur in nested scoping constructs *)
With[{a=3},HoldForm@Module[{x},x+a]]
(* Module[{x$}, x$ +3] *)
Module[{a = 0}, HoldForm@Compile[{x,y}, a x + y]]
(* Compile[{x$,y$}, a$6234 x$ + y$] *)
x = 2; y = 6;
Function[a,HoldForm[f[x_,y_] = a x + y]][7]
(* f[x$_, y$_] = 7 x$ + y$ *)

(* Block does not participate in these lexical scoping activities. If inside, its variables are not renamed *)
Module[{a = 0}, HoldForm@Block[{x,y}, a x + y]]
(* Block[{x,y}, a$6235 x + y] *)
(* If outside, then it does not rename the construct inside *)
Block[{a=0}, HoldForm@Module[{x,y}, a x + y]]
(* Module[{x,y}, a x + y] *)
