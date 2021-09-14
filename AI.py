from godot import exposed, export
from godot import *
import torch as T
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import numpy as np

class DeepQNetwork(nn.Module):
	def __init__(self, lr, input_dims, fc1_dims, fc2_dims, 
			n_actions):
		super(DeepQNetwork, self).__init__()
		self.input_dims = input_dims
		self.fc1_dims = fc1_dims
		self.fc2_dims = fc2_dims
		self.n_actions = n_actions
		self.fc1 = nn.Linear(*self.input_dims, self.fc1_dims)
		self.fc2 = nn.Linear(self.fc1_dims, self.fc2_dims)
		self.fc3 = nn.Linear(self.fc2_dims, self.n_actions)

		self.optimizer = optim.Adam(self.parameters(), lr=lr)
		self.loss = nn.MSELoss()
		self.device = T.device('cuda:0' if T.cuda.is_available() else 'cpu')
		print('cuda:0' if T.cuda.is_available() else 'cpu')
		
		self.to(self.device)

	def forward(self, state):
		x = F.relu(self.fc1(state))
		x = F.relu(self.fc2(x))
		actions = self.fc3(x)

		return actions

class Agent():
	def __init__(self, gamma, epsilon, lr, input_dims, batch_size, n_actions,
			max_mem_size=10000, eps_end=0.01, eps_dec=5e-6):
		self.gamma = gamma
		self.epsilon = epsilon
		self.eps_min = eps_end
		self.eps_dec = eps_dec
		self.lr = lr
		self.action_space = [i for i in range(n_actions)]
		self.mem_size = max_mem_size
		self.batch_size = batch_size
		self.mem_cntr = 0
		self.iter_cntr = 0
		self.replace_target = 2000

		self.Q_eval = DeepQNetwork(lr, n_actions=n_actions, input_dims=input_dims,
									fc1_dims=128, fc2_dims=128)
		self.Q_next = DeepQNetwork(lr, n_actions=n_actions, input_dims=input_dims,
									fc1_dims=128, fc2_dims=128)

		self.state_memory = np.zeros((self.mem_size, *input_dims), dtype=np.float32)
		self.new_state_memory = np.zeros((self.mem_size, *input_dims), dtype=np.float32)
		self.action_memory = np.zeros(self.mem_size, dtype=np.int32)
		self.reward_memory = np.zeros(self.mem_size, dtype=np.float32)
		self.terminal_memory = np.zeros(self.mem_size, dtype=np.bool)
		
		
		self.deaths=0

	def store_transition(self, state, action, reward, state_, terminal):
		index = self.mem_cntr % self.mem_size
		self.state_memory[index] = state
		self.new_state_memory[index] = state_
		self.reward_memory[index] = reward
		self.action_memory[index] = action
		self.terminal_memory[index] = terminal

		self.mem_cntr += 1

	def choose_action(self, observation):
		if np.random.random() > self.epsilon:
			state = T.tensor([observation]).to(self.Q_eval.device)
			actions = self.Q_eval.forward(state)
			action = T.argmax(actions).item()
		
		
		else:
			action = np.random.choice(self.action_space)

		return action

	def learn(self):
		if self.mem_cntr < self.batch_size:
			return

		self.Q_eval.optimizer.zero_grad()

		max_mem = min(self.mem_cntr, self.mem_size)

		batch = np.random.choice(max_mem, self.batch_size, replace=False)
		
		batch_index = np.arange(self.batch_size, dtype=np.int32)

		state_batch = T.tensor(self.state_memory[batch]).to(self.Q_eval.device)
		new_state_batch = T.tensor(self.new_state_memory[batch]).to(self.Q_eval.device)
		action_batch = self.action_memory[batch]
		reward_batch = T.tensor(self.reward_memory[batch]).to(self.Q_eval.device)
		terminal_batch = T.tensor(self.terminal_memory[batch]).to(self.Q_eval.device)

		q_eval = self.Q_eval.forward(state_batch)[batch_index, action_batch]
		q_next = self.Q_eval.forward(new_state_batch)
		q_next[terminal_batch] = 0.0

		q_target = reward_batch + self.gamma*T.max(q_next,dim=1)[0]

		loss = self.Q_eval.loss(q_target, q_eval).to(self.Q_eval.device)
		loss.backward()
		self.Q_eval.optimizer.step()

		self.iter_cntr += 1
		self.epsilon = self.epsilon - self.eps_dec if self.epsilon > self.eps_min \
					   else self.eps_min
					
#		if self.iter_cntr % self.replace_target == 0:
#
#			self.Q_next.load_state_dict(self.Q_eval.state_dict())




@exposed
class AI(Node2D):
	
	print('----------------ddd-----')
	
	def _ready(self):
		self.agent = Agent(gamma=0.99,epsilon=1.0,batch_size=256, n_actions=4,eps_end=0.02,input_dims=[13],lr=0.001)
		print('readya')
		
	def get_action(self,observation):
		o = np.array(observation,dtype=np.float32).flatten()
		action = self.agent.choose_action(o)
#		action = 1
		return int(action)
	
	def store_transition(self, observation, action, reward, observation_, done):
		o = np.array(observation,dtype=np.float32).flatten()
		o_ = np.array(observation_,dtype=np.float32).flatten()
		self.agent.store_transition(o,action,reward,o_,done)
		
	def learn(self):
		self.agent.learn()
		
	def get_epsilon(self):
		return self.agent.epsilon
		
	def died(self):
		self.agent.deaths+=1
	def death_count(self):
		return int(self.agent.deaths)
	def memory_count(self):
		return int(self.agent.mem_cntr % self.agent.mem_size)
	


	
	
	
	
	
	
	
