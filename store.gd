# Godot Redux - A gdscript implementation of Redux.
#
# Redux is a way to manage and update your application's state using events
# called actions. The Redux store serves as a centralized place for data that
# can be used across your entire application.
#
# ## Concepts
#
# The data in Redux is immutable. While this would be great to be able to
# enforce in gdscript, it is not currently possible and so it is up to you to
# follow the rules and best practices of how to modify data in your actions as
# you'll see further down in the Reducers section.
#
# ### State
#
# The state in redux is stored in an object called the store. While this can be
# anything, most of the time you'll be using a dictionary of values. Let's take
# a look at a simple state that has a counter variable:
#
# ```
# const state = {
#     "counter": 0
# }
# ```
#
# ### 
#
# Action are the only way to change the state of a Redux application and in
# gdscript they are represented by an enum. Let's expand the simple counter
# example from above and create actions to increment and decrement the counter.
#
# ```
# enum Action {
#     INCREMENT,
#     DECREMENT,
# }
# ```
#
# ### Reducers
#
# To actually change the values in the state, we need to create reducers. A
# reducer is a function that takes the current state and an action and decides
# how to update the state if necessary. The example below shows how to create a
# reducer for incrementing and decrementing the counter:
#
# ```
# const state = {
#     "counter": 0,
# }
#
# enum Action {
#     INCREMENT,
#     DECREMENT,
# }
#
# func reducer(state, action):
#     match action:
#         Action::INCREMENT:
#             return {
#                 "counter": state.counter + 1,
#             }
#         Action::DECREMENT:
#             return {
#                 "counter": state.counter - 1,
#             }
# ```
#
# A couple things to keep in mind here. First we have to again stress that the
# state is immutable. This means that you MUST return a new state from your
# reducer. Second, while you have to return a new state, you can use values from
# your old state data to create the new state.
#
# ### Store
#
# So far we've discussed the core components and can put them together into the
# store. The store must be instanced with the initial state, the current
# instance, and the name of the reducer function. The current instance and the
# reducer function name must be provided so that we can keep a reference to it.
# A full example with the store can look like:
#
# ```
# const state = {
#     "counter": 0,
# }
#
# enum Action {
#     INCREMENT,
#     DECREMENT,
# }
#
# func reducer(state, action):
#     match action:
#         Action::INCREMENT:
#             return {
#                 "counter": state.counter + 1,
#             }
#         Action::DECREMENT:
#             return {
#                 "counter": state.counter - 1,
#             }
#
# func _ready():
#     var store = Store.new(state, self, 'reducer')
# ```
#
# ### Dispatch
#
# To actually update the store you have to use the `dispatch` method with the
# action you want to run. This will cause the store to run the reducer function
# and save the new state value.
#
# ```
# store.dispatch(Action.INCREMENT)
# ```
#
# This will make the store run the reducer for `INCREMENT` and make the counter
# go from 0 to 1.
#
# ### Subscriptions
#
# To listen for changes to the state you can use a subscription. The
# subscription will be called any time an action is dispatched, and some of the
# state might have changed. To create a subscriber, you have to pass the
# instance and the name of the function that should be run when the state is
# changed like so:
#
# ```
# func _ready():
#     var store = Store.new(state, self, 'reducer')
#     store.subscribe(self, 'display_counter')
#
# func display_counter(state):
#     print(state.counter)
# ```
#
# Now whenever the state is changed with dispatch, the `display_counter`
# function will be run and the counter will be printed to the console.
#
# ### Middleware
#
# Middleware is used to customize the dispatch function. This is done by
# providing you a point between dispatching an action and it reaching the
# reducer. Each piece of middleware added will use the action returned by the
# previous middleware and if nothing is returned then the middleware chain stops
# being processed.
#
# Below is an example of a middleware function that will take the current action
# and reverse it:
#
# ```
# func reverse_middleware(state, action):
#     match action {
#         Action::INCREMENT:
#             return Action::DECREMENT
#         Action::DECREMENT:
#             return Action::INCREMENT
#
# func _ready():
#     var store = Store.new(state, self, 'reducer')
#     store.add_middleware(self, 'reverse_middleware')
#
#     # This will actually run the `DECREMENT` action because of our middleware.
#     store.dispatch(Action::INCREMENT)
# ```
class_name Store

# The state is the source of truth of the application's data.
var _state
# The reducer function that decides how to update the state based on the action.
var _reducer
# The middleware functions used to intercept the actions and change them before
# they reach the reducer.
var _middleware = []
# The callback functions to run when the state is changed.
var _subscriptions = []

# Creates a new Store.
#
# @param state - The initial state of the application.
# @param reducer_instance - The instance on which the reducer exists.
# @param reducer - The reducer function.
#
# Example:
#
# ```
# const state = {
#     "counter": 0,
# }
#
# enum Action {
#     INCREMENT,
#     DECREMENT,
# }
#
# func reducer(state, action):
#     match action:
#         Action::INCREMENT:
#             return {
#                 "counter": state.counter + 1,
#             }
#         Action::DECREMENT:
#             return {
#                 "counter": state.counter - 1,
#             }
#
# func _ready():
#     var store = Store.new(state, self, 'reducer')
# ```
func _init(state, reducer_fn_instance, reducer_fn_name):
	self._state = state
	self._reducer = funcref(reducer_fn_instance, reducer_fn_name)

# Returns the current state.
#
# Example:
#
# ```
# func _ready():
#     var store = Store.new(state, self, 'reducer')
#     print(store.state())
# ```
func state():
	return self._state

# Dispatches an action to update the state.
#
# @param action - The action to dispatch.
#
# Example:
#
# ```
# const state = {
#     "counter": 0,
# }
#
# enum Action {
#     INCREMENT,
#     DECREMENT,
# }
#
# func reducer(state, action):
#     match action:
#         Action::INCREMENT:
#             return {
#                 "counter": state.counter + 1,
#             }
#         Action::DECREMENT:
#             return {
#                 "counter": state.counter - 1,
#             }
#
# func _ready():
#     var store = Store.new(state, self, 'reducer')
#     store.dispatch(Action::INCREMENT)
# ```
func dispatch(action):
	if self._middleware.empty():
		self._dispatch_reducer(action)
	else:
		self._dispatch_middleware(0, action)
	
# Runs a single middleware function. If the middleware function returns an
# action then it runs the next middleware function in the middlewares array with
# the action returned by the previous one.
#
# @private
#
# @param index - The index of the middleware function to run from the array.
# @param action - The action to pass to the middleware function.
func _dispatch_middleware(index: int, action):
	if index == self._middleware.size():
		self._dispatch_reducer(action)
		return
	
	var next = self._middleware[index].call_func(action)
	
	if next != null:
		self._dispatch_middleware(index + 1, next)

# Runs the reducer for the specified action and then dispatch any subscriptions.
#
# @private
#
# @param action - The action to run the reducer for.
func _dispatch_reducer(action):
	self._state = self._reducer.call_func(self._state, action)
	self._dispatch_subscriptions()

# Runs the subscriptions for the store.
#
# @private
func _dispatch_subscriptions():
	for subscription in self._subscriptions:
		subscription.call_func(self._state)

# Subscribes to changes to the state. When a change to the state is made, the
# callback function is run and passed the current state as an argument.
#
# @param callback_fn_instance - The instance that contains the callback function.
# @param callback_fn_name - The name of the callback function.
#
# Example:
#
# ```
# const state = {
#     "counter": 0,
# }
#
# enum Action {
#     INCREMENT,
#     DECREMENT,
# }
#
# func reducer(state, action):
#     match action:
#         Action::INCREMENT:
#             return {
#                 "counter": state.counter + 1,
#             }
#         Action::DECREMENT:
#             return {
#                 "counter": state.counter - 1,
#             }
#
# func _ready():
#     var store = Store.new(state, self, 'reducer')
#     store.subscribe(self, 'print_counter')
# 
# func print_counter(state):
#     print(state.counter)
# ```
func subscribe(callback_fn_instance, callback_fn_name):
	var subscribe_ref = funcref(callback_fn_instance, callback_fn_name)
	self._subscriptions.append(subscribe_ref)

# Adds a middleware function that can intercept a dispatch and modify the action
# to be run before it reaches the reducer.
#
# @param middleware_fn_instance - The instance that contains the middleware function.
# @param middleware_fn_name - The name of the middleware function.
#
# Example:
#
# ```
# func reverse_middleware(state, action):
#     match action {
#         Action::INCREMENT:
#             return Action::DECREMENT
#         Action::DECREMENT:
#             return Action::INCREMENT
#
# func _ready():
#     var store = Store.new(state, self, 'reducer')
#     store.add_middleware(self, 'reverse_middleware')
#
#     # This will actually run the `DECREMENT` action because of our middleware.
#     store.dispatch(Action::INCREMENT)
# ```
func add_middleware(middleware_fn_instance, middleware_fn_name):
	var middleware_ref = funcref(middleware_fn_instance, middleware_fn_name)
	self._middleware.append(middleware_ref)
