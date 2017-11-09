-- Network: COnvolutional Neural Network
-- Application: Object Detection
-- Dataset: Imagenet
-- Number of parameters:
-- Reference: Google search

-- How to interpret I/O data sizes?
-- batchsize * input_size
-- A batch - multiple inputs

torch.setdefaulttensortype('torch.FloatTensor')
require 'xlua'
require 'sys'
cmd = torch.CmdLine()
cmd:option('-gpu', 0, 'Run on CPU/GPU')
cmd:option('-threads', 2, 'Number of threads for CPU')
cmd:option('-batch', 1, 'Number of batches')
opt = cmd:parse(arg or {})
torch.setnumthreads(opt.threads)

-- dnn hyper-parameters
batchsize = opt.batch
num_inDim = 3
inputsize = 224
outputsize = 1000

-- build dnn
-- vgg 16 layer-wise data (from cs231, insigts into input size transactions occuring)
--[[
INPUT:     [224x224x3]    memory:  224*224*3=150K   weights: 0
CONV3-64:  [224x224x64]   memory:  224*224*64=3.2M  weights: (3*3*3)*64 = 1,728
CONV3-64:  [224x224x64]   memory:  224*224*64=3.2M  weights: (3*3*64)*64 = 36,864
POOL2:     [112x112x64]   memory:  112*112*64=800K  weights: 0
CONV3-128: [112x112x128]  memory:  112*112*128=1.6M weights: (3*3*64)*128 = 73,728
CONV3-128: [112x112x128]  memory:  112*112*128=1.6M weights: (3*3*128)*128 = 147,456
POOL2:     [56x56x128]    memory:  56*56*128=400K   weights: 0
CONV3-256: [56x56x256]    memory:  56*56*256=800K   weights: (3*3*128)*256 = 294,912
CONV3-256: [56x56x256]    memory:  56*56*256=800K   weights: (3*3*256)*256 = 589,824
CONV3-256: [56x56x256]    memory:  56*56*256=800K   weights: (3*3*256)*256 = 589,824
POOL2:     [28x28x256]    memory:  28*28*256=200K   weights: 0
CONV3-512: [28x28x512]    memory:  28*28*512=400K   weights: (3*3*256)*512 = 1,179,648
CONV3-512: [28x28x512]    memory:  28*28*512=400K   weights: (3*3*512)*512 = 2,359,296
CONV3-512: [28x28x512]    memory:  28*28*512=400K   weights: (3*3*512)*512 = 2,359,296
POOL2:     [14x14x512]    memory:  14*14*512=100K   weights: 0
CONV3-512: [14x14x512]    memory:  14*14*512=100K   weights: (3*3*512)*512 = 2,359,296
CONV3-512: [14x14x512]    memory:  14*14*512=100K   weights: (3*3*512)*512 = 2,359,296
CONV3-512: [14x14x512]    memory:  14*14*512=100K   weights: (3*3*512)*512 = 2,359,296
POOL2:     [7x7x512]      memory:  7*7*512=25K      weights: 0
FC:        [1x1x4096]     memory:  4096             weights: 7*7*512*4096 = 102,760,448
FC:        [1x1x4096]     memory:  4096             weights: 4096*4096 = 16,777,216
FC:        [1x1x1000]     memory:  1000             weights: 4096*1000 = 4,096,000
TOTAL params: 138M parameters
--]]

require 'nn'
local num_params = 0


model = nn.Sequential()
model:add(nn.SpatialConvolution(3, 64, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialConvolution(64, 64, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialMaxPooling(2, 2, 2, 2))
model:add(nn.SpatialConvolution(64, 128, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialConvolution(128, 128, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialMaxPooling(2, 2, 2, 2))
model:add(nn.SpatialConvolution(128, 256, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialConvolution(256, 256, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialConvolution(256, 256, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialMaxPooling(2, 2, 2, 2))
model:add(nn.SpatialConvolution(256, 512, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialConvolution(512, 512, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialConvolution(512, 512, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialMaxPooling(2, 2, 2, 2))
model:add(nn.SpatialConvolution(512, 512, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialConvolution(512, 512, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialConvolution(512, 512, 3, 3, 1, 1, 1, 1, 1))
model:add(nn.ReLU(true))
model:add(nn.SpatialMaxPooling(2, 2, 2, 2))
model:add(nn.View(-1):setNumInputDims(3))
model:add(nn.Linear(25088, 4096))
model:add(nn.ReLU(true))
model:add(nn.Linear(4096, 4096))
model:add(nn.ReLU(true))
model:add(nn.Linear(4096, outputsize))

num_params = 3*64*(3^2) + 64*64*(3^2) + 64*128*(3^2) + 128*128*(3^2) +
                  128*256*(3^2) + 256*256*(3^2) + 256*256*(3^2) +
                  256*512*(3^2) + 512*512*(3*2) + 512*512*(3^2) +
                  512*512*(3*2) + 512*512*(3^2) + 512*512*(3*2) +
                  (25088+1)*4096 + (4096+1)*4096 + (4096+1)*1000
                  -- + 64*2 + 128*2 + 256*3 + 512*6 -- add bias for conv layer

print (model)
print (num_params)

-- create input and output tensors
input = torch.Tensor(batchsize, num_inDim, inputsize, inputsize)
output = torch.Tensor(batchsize, outputsize)

-- dnn inference model
local run_dnn = function()
    print('==> Type is '..input:type())
    output = model:forward(input)
end

-- for running on GPU/CPU
if (opt.gpu == 1) then -- GPU run
  require 'cunn'
  model = model:cuda() -- move the model, i/o data to gpu memory
  input = input:cuda()
  output = output:cuda()
  cmdstring="nvidia-smi -i 0 --query-gpu=power.limit,power.draw,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free --format=csv,nounits --loop-ms=500> ./nmt_l3_gpulog_batchsize_%d.txt &"% (batchsize)
  os.execute(cmdstring)
  -- measure gpu time
  gputime0 = sys.clock()
  run_dnn()
  gputime1 = sys.clock()
  -- run nvidia-smi for gpu power (Think about the placment of this later?)
  os.execute ('nvidia-smi -q -d POWER > ./rnnTest_gpuPow.txt')
  gputime = gputime1 - gputime0
  print('GPU Time: '.. (gputime*1000) .. 'ms')
  os.execute('kill -9 `pidof nvidia-smi`')
else -- CPU run
  -- measure CPU latency
  cputime0 = sys.clock()
  run_dnn()
  cputime1 = sys.clock()
  cputime = cputime1 - cputime0
  print('CPU Time: '.. (cputime*1000) .. 'ms')
end


