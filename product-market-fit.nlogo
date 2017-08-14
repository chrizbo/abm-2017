extensions [ nw ]

breed [ producers producer ]
breed [ consumers consumer ]

producers-own [
  value-prop
  effort
]

consumers-own [
  underserved-need
  current-value-prop
  need-met?
]

to setup
  ca

  ;; setting this manually for now, may expose via interface soon
  let num-agents 50

  set-default-shape producers "house"
  set-default-shape consumers "person"

  ;; setup network of consumers
  nw:generate-preferential-attachment consumers links num-agents [
    setxy random-xcor random-ycor
    set color white

    ;; Q: do we need to set the underserved-need to be similar between consumers?
    set underserved-need n-values traits [(random features) + 1]

    set current-value-prop n-values traits [ 0 ]
    set need-met? false
  ]

  ;; create a producer
  create-producers 1 [
    setxy 0 0
    set size 2
    set color red
    set effort 0
    init-value-prop
  ]

  reset-ticks
end

to go
  ;; if all consumers have bought the solution then stop!
  if count consumers with [ need-met? = false ] = 0 [
    stop
  ]

  ;; stop if you hit 10,000 ticks
  if ticks > 10000 [
    stop
  ]

  ;; consumers should look at other consumers connected to them and alter their underserved-need to be more similar to their peers
  ;; like the culture spread by Alexrod
  let last-diff [ 0 ]

  ;; consumers should see if the producer's value-prop is better than their current-value-prop in fitting their underserved-need
  ;; if so, buy new producers value-prop
  ask consumers [
    set last-diff product-market-distance self one-of producers

    ;; if product-market-fit? self one-of producers [
    if sum last-diff = 0 [
      ;; if the producer(s) matches the consumer's need then mark it
      set color red
      set current-value-prop one-of producers
      set need-met? true
    ]
  ]

  ;; have producers, based on their strategy, alter their value-prop based on feedback from customers
  ask producers [
    update-value-prop last-diff
  ]

  ;; Q: should consumers 'un-buy' the solution if their underserved-need is too different from their current value-prop?
  ;; should there be a list of other producers that are waiting in the wing to take on the consumers with different value-props?

  tick
end

to reset
  ;; reset consumers
  ask consumers [
    set color white
    set underserved-need n-values traits [(random features) + 1]
    set current-value-prop n-values traits [ 0 ]
    set need-met? false
  ]

  ;; reset producer
  ask producers [
    set effort 0
    init-value-prop
  ]

  clear-all-plots

  reset-ticks
end

;; to-report consumer-decision method to decide if the consumer should buy the producers value-prop based on distance away within some threshold

to-report product-market-fit? [ consumer1 producer1 ]
  ifelse sum product-market-distance consumer1 producer1 = 0 [
    report true
  ] [
    report false
  ]
end

to-report product-market-distance [ consumer1 producer1 ]
  let value-prop1 [ value-prop ] of producer1
  let underserved-need1 [ underserved-need ] of consumer1

  let product-market-difference ( map [ [ a b ] -> a - b ] value-prop1 underserved-need1 )

  report product-market-difference
end

;; producer strategies
to init-value-prop
  set value-prop n-values traits [(random features) + 1]
end

to update-value-prop [ product-market-difference ]
  if producer-strategy = "random" [
    update-value-prop-random
  ]

  if producer-strategy = "feedback" [
    let current-diff product-market-difference
    update-value-prop-feedback current-diff
  ]

  if producer-strategy = "fixed" [
    ;; fixed does nothing after the first generation
  ]
end

;; constant explore (custom solutions) - randomly change value-prop every sale
to update-value-prop-random
  ;; product-market-difference is ignored
  set value-prop n-values traits [(random features) + 1]
  set effort effort + 1
end

;; mixture of explore vs. exploit - small adjustments based on feedback from customers
to update-value-prop-feedback [ product-market-difference ]
  set value-prop ( map [ [ a b ] -> a - b ] value-prop product-market-difference )
  set effort effort + 1
end

;; mixture of explore vs. exploit - batches of customer feedback to make adjustments
@#$#@#$#@
GRAPHICS-WINDOW
242
11
679
449
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
20
194
86
227
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
161
195
224
228
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
92
194
155
227
NIL
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
18
23
219
56
traits
traits
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
19
81
221
114
features
features
0
10
4.0
1
1
NIL
HORIZONTAL

PLOT
18
300
218
450
consumers sold
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"plot-pen-reset" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count consumers with [ need-met? ]"

CHOOSER
18
131
221
176
producer-strategy
producer-strategy
"random" "feedback" "fixed"
0

MONITOR
25
243
187
288
effort
[ effort ] of one-of producers
17
1
11

@#$#@#$#@
# ABM course info

## Model Scope

Finding product/market fit through interactions with consumers. There are many different product development strategies (e.g. early feedback, getting to market first, etc.) and this model starts to analyze the impact is for these different strategies on longer term sales (the end goal of startups).

This NetLogo model simulates the process by which producers find product market fit with consumers. Product market fit is how a producer's value proposition of their product matches the consumer's underserved needs. 

The goal of the model is to see how much effort is required to find product-market fit based on different product development strategies. 

## Agent Selection

Two principal types of agents:

* Producers - creators of products or services that want to have consumers eventually buy them.
* Consumers - people that need or want products and services and are willing to buy them if they meet enough of their needs at the right time.

## Agent Properties

Producers:

* value-prop - a culture-like set of traits and features meant to represent the value proposition for the producer.
* effort - amount of effort in changing the value proposition to find product-market fit.

Consumers:

* underserved-need - a culture-like set of traits and features meant to represent the ideal need for the consumer. 
* current-value-prop - the current product that the consumer has purchased.
* need-met? - whether or not the consumer has purchased a solution.

## Agent Actions

Producers:

* Attempt to sell their product to a consumer
* Update their value proposition based on the customer's feedback

Customers:

* Buy a product from a producer if the value proposition meets their needs

## Environment

The environment is a network of consumers that the producer has access to.

## Order of Events

1. Ask every consumer to compare their unmet need with the producers value proposition
2. If the consumer is matched then their need is met
3. Ask producer to update their value proposition based on their strategy

## Inputs and Output

Inputs:

* Number of traits and features per trait
* Producer's strategy

Outputs:

* Total effort expended by the producer
* Graph of number of consumers that have bought the producer's product
* World network of consumers that turn red when they have bought the producer's product

## Model Execution

The model will run until all consumers are sold or 10,000 ticks, whichever comes first. 

A Behavior Space experiment has been setup to explore the different producer strategies.

## User Interface

* Setup - creates a new network of consumers (with unmet needs) and producer (with a value proposition)
* Reset - keeps the consumer network, but resets the purchases
* Go - starts the model running

## Model Documentation

See the standard ABM info content below.

# Standard ABM info content

## WHAT IS IT?

Finding product/market fit through interactions with consumers. There are many different product development strategies (e.g. early feedback, getting to market first, etc.) and this model starts to analyze the impact is for these different strategies on longer term sales (the end goal of startups).

This NetLogo model simulates the process by which producers find product market fit with consumers. Product market fit is how a producer's value proposition of their product matches the consumer's underserved needs. 

![Product-Market Fit Pyramid](https://github.com/chrizbo/abm-2017/blob/master/product-market-fit-docs/product-market-fit.png?raw=true)

For more information see this Mind the Product post:

http://www.mindtheproduct.com/2017/07/the-playbook-for-achieving-product-market-fit/

The goal of the model is to see how much effort is required to find product-market fit based on different product development strategies. 

## HOW IT WORKS

Two principal types of agents:

* Producers - creators of products or services that want to have consumers eventually buy them.
* Consumers - people that need or want products and services and are willing to buy them if they meet enough of their needs at the right time.

Producers have a value proposition that is in the format of a product hypothesis. This is the product that they are testing out, building, or selling. This will be represented as an array of features. Inspired by Alexrod and his work on culture dissemination:

https://deepblue.lib.umich.edu/bitstream/handle/2027.42/67489/10.1177_0022002797041002001.pdf

Consumers have an underserved need that the producers attempt to fill with their product offering. This is represented as an array of features like the producer and when they match within a necessary threshold the consumer will buy the product. 

The producers can use different strategies when getting feedback from consumers: 

* Fixed - leave things the way they are (no feedback and sure of their solution)
* Random - randomly change their offering (no feedback and not sure of their solution)
* Feedback - based on the mismatch between the value proposition and the underserved need the producer will update their offering.

When they change their product effort is expended to change the value proposition of the product. 

## HOW TO USE IT

As with the Axelrod model you can change the number of traits and features for the value proposition (and underserved need for consumers). 

Also, you can select which strategy the producer will use through the chooser box. 

Setup will generate a new set of consumers and one producer. Reset will keep the same consumer network, but reset all values.

There are two main ways to monitor the model as it progresses:

* Effort - the raw amount of effort used by the producer to update their value proposition.
* Consumers sold - the graph of consumers that have purchased the producer's product based on matching their underserved need.

In the world you will see all consumers start with a white color when they do not have a solution. When they are sold a solution they turn red.

## THINGS TO NOTICE

What has been most interesting so far is that the random strategy uses slightly more effort on average, but does about as well as the feedback strategy. 

More analysis of the different strategy's results can be found in the analysis notebook:

https://github.com/chrizbo/abm-2017/blob/master/product-market-fit-analysis.ipynb

## THINGS TO TRY

A few things to try:

* Increase the number of traits and features
* Try different strategies

## EXTENDING THE MODEL

The most interesting extensions to the model will be adding new strategies for the producers to try. For example:

* Batch based feedback - collect feedback and change based on batches of average feedback
* Small changes - drift towards consumer's unmet needs rather than making huge changes. 

A few other aspects that would extend the model:

* Network-based dissemination for consumers of products they have bought
* Implement a threshold which the consumers will accept an imperfect value prop
* Change the number of consumers that are in the pool to see how different strategies work for different sizes of customer pools
* Don't allow producers to sell to consumers every turn to more realistically simulate the fact that sales cycles

## RELATED MODELS

The inspiration for the culture aspects was from this model:

http://ccl.northwestern.edu/netlogo/models/community/Axelrod%20-%20Network

## CREDITS AND REFERENCES

Axelrod's The Dissemination of Culture paper has been a huge inspiration for how to model the producer's value proposition and the consumer's unmet need:

https://deepblue.lib.umich.edu/bitstream/handle/2027.42/67489/10.1177_0022002797041002001.pdf

You can find the latest version of the model on github:

https://github.com/chrizbo/abm-2017

Thank you.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Strategy comparisons" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count consumers with [ need-met? ]</metric>
    <metric>[ effort ] of one-of producers</metric>
    <enumeratedValueSet variable="traits">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="producer-strategy">
      <value value="&quot;random&quot;"/>
      <value value="&quot;feedback&quot;"/>
      <value value="&quot;fixed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="features">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
