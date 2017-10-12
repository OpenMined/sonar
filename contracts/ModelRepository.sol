pragma solidity ^0.4.4;

contract ModelRepository {

  Model[] models;
  Gradient[] grads;

  struct IPFS {
    bytes32 first;
    bytes32 second;
  }

  struct Gradient {

    bool evaluated;

    // submitted from miner
    address from;
    IPFS grads;
    uint model_id;

    // submitted from trainer
    uint new_model_error;
    IPFS new_weights;
  }

  struct Model {

    address owner;

    IPFS init_weights;
    IPFS weights;

    uint bounty;

    uint initial_error;
    uint best_error;
    uint target_error;

  }

  modifier onlyByModelOwner(uint _gradient_id) {
    require(msg.sender == models[grads[_gradient_id].model_id].owner);
     _;
  }

  modifier onlyIfGradientNotYetEvaluated(uint _gradient_id) {
    require(grads[_gradient_id].evaluated == false);
    _;
  }

  function transferAmount(address receiver, uint amount) private {
    assert(receiver.send(amount));
  }

  function addModel(bytes32[] _weights, uint initial_error, uint target_error) payable {

    IPFS memory weights;
    weights.first = _weights[0];
    weights.second = _weights[1];

    Model memory newModel;
    newModel.weights = weights;
    newModel.init_weights = weights;

    newModel.bounty = msg.value;
    newModel.owner = msg.sender;

    newModel.initial_error = initial_error;
    newModel.best_error = initial_error;
    newModel.target_error = target_error;

    models.push(newModel);
  }

  function incentiveCalculate(uint bounty, uint total_error, uint solved_error) returns(uint total) {
    total = ((bounty/total_error) * solved_error);
    return total;
  }

  function evalGradient(uint _gradient_id, uint _new_model_error, bytes32[] _new_weights_addr) onlyByModelOwner(_gradient_id) onlyIfGradientNotYetEvaluated(_gradient_id) {
    grads[_gradient_id].new_weights.first = _new_weights_addr[0];
    grads[_gradient_id].new_weights.second = _new_weights_addr[1];
    grads[_gradient_id].new_model_error = _new_model_error;

    //transferAmount(grads[_gradient_id].from,1);

    Model model = models[grads[_gradient_id].model_id];
    
    if(_new_model_error < model.best_error && model.target_error < model.best_error) {
      uint total_error= model.initial_error - model.target_error;
      uint solved_error= model.best_error - _new_model_error;
      uint incentive = incentiveCalculate(model.bounty, total_error, solved_error);

      model.best_error = _new_model_error;
      model.weights = grads[_gradient_id].new_weights;
      transferAmount(grads[_gradient_id].from, incentive);
    }

    grads[_gradient_id].evaluated = true;
  }
  
  function addGradient(uint model_id, bytes32[] _grad_addr) {
    require(models[model_id].owner != 0);
    IPFS memory grad_addr;
    grad_addr.first = _grad_addr[0];
    grad_addr.second = _grad_addr[1];

    IPFS memory new_weights;
    new_weights.first = 0;
    new_weights.second = 0;

    Gradient memory newGrad;
    newGrad.grads = grad_addr;
    newGrad.from = msg.sender;
    newGrad.model_id = model_id;
    newGrad.new_model_error = 0;
    newGrad.new_weights = new_weights;
    newGrad.evaluated=false;

    grads.push(newGrad);
  }

  function getNumModels() constant returns(uint256 model_cnt) {
    return models.length;
  }

  function getNumGradientsforModel(uint model_id) constant returns (uint num) {
    num = 0;
    for (uint i=0; i<grads.length; i++) {
      if(grads[i].model_id == model_id) {
        num += 1;
      }
    }
    return num;
  }

  function getGradient(uint model_id, uint gradient_id) constant returns (uint, address, bytes32[], uint, bytes32[]) {
    uint num = 0;
    for (uint i=0; i<grads.length; i++) {
      if(grads[i].model_id == model_id) {
        if(num == gradient_id) {

          bytes32[] memory _grad_addr = new bytes32[](2);

          _grad_addr[0] = grads[i].grads.first;
          _grad_addr[1] = grads[i].grads.second;

          bytes32[] memory _new_weghts_addr = new bytes32[](2);
          _new_weghts_addr[0] = grads[i].new_weights.first;
          _new_weghts_addr[1] = grads[i].new_weights.second;

          return (i, grads[i].from, _grad_addr, grads[i].new_model_error, _new_weghts_addr);
        }
        num += 1;
      }
    }
  }

  function getModel(uint model_i) constant returns (address,uint,uint,uint,bytes32[]) {

    Model memory currentModel;
    currentModel = models[model_i];
    bytes32[] memory _weights = new bytes32[](2);

    _weights[0] = currentModel.weights.first;
    _weights[1] = currentModel.weights.second;

    return (currentModel.owner, currentModel.bounty, currentModel.initial_error, currentModel.target_error, _weights);
  }

}
