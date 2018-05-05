pragma solidity ^0.4.20;

contract Exchange{

    //This struct represents product from farm.
    //farmProductTag: Tag of farmer's product
    //amount        : Amount of product
    //owner         : owner of product
    struct FarmProduct{
        bytes32 farmProductTag;
        uint amount;
        address owner;
    }
    address FARMER_CONTRACT;

    //This mapping represents farmProduct usually for farmer to sell to distributor
    mapping(bytes32 => FarmProduct) farmProduct;

    //This mapping represents distributor's farm product that hold
    mapping(address => mapping(bytes32 => uint)) distributor;

    //Constructure
    function Exchange()public{

    }

    //This function use to initial farmer contract ONLY USE ONCE
    function initFARMERCONTRACT(address _FARMER_CONTRACT)public{
        require(FARMER_CONTRACT == address(0));
        FARMER_CONTRACT = _FARMER_CONTRACT;
    }

    //This function use to add harvested product to this contract
    function addProduct(bytes32 _farmProductTag, uint _amount, address _owner,address _FARMER_CONTRACT)public{
        require(_FARMER_CONTRACT == FARMER_CONTRACT);
        farmProduct[_farmProductTag].farmProductTag = _farmProductTag;
        farmProduct[_farmProductTag].amount = _amount;
        farmProduct[_farmProductTag].owner = _owner;
    }

    //This function is for distributor who wwant to buy product from farmer
    function buyFromFarmer(bytes32 _farmProductTag, uint _amount)public payable{
        require(farmProduct[_farmProductTag].amount >= _amount);
        farmProduct[_farmProductTag].amount -= _amount;
        distributor[msg.sender][_farmProductTag] += _amount;
        farmProduct[_farmProductTag].owner.transfer(msg.value);
    }

    //This function is for distributor who wwant to buy product from other distributor
    function buyFromDistributor(bytes32 _farmProductTag, uint _amount, address _owner)public payable{
        require(distributor[_owner][_farmProductTag] >= _amount);
        distributor[_owner][_farmProductTag] -= _amount;
        distributor[msg.sender][_farmProductTag] += _amount;
        _owner.transfer(msg.value);
    }

    //This function use to burn product when sell to retail store such as top
    function retailStore(bytes32 _farmProductTag, uint _amount)public{
        require(distributor[msg.sender][_farmProductTag]  >= _amount);
        distributor[msg.sender][_farmProductTag] -= _amount;
    }

}
