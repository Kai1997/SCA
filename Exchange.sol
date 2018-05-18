pragma solidity ^0.4.20;

contract Exchange{

    //This struct represents product from farm.
    //farmProductId : Id of this farmer's product
    //farmProductTag: Tag to identify farmer's product
    //owner         : current owner of this product
    //totalSupply   : Total supply of this product
    //currentSupply : Supply remaining on this product
    //parentFarmProduct : Identify which farmProductId that this product obtain from
    //childFarmProduct  : Identify where farm products are divide to
    struct FarmProduct{
        bytes32 farmProductId;
        bytes32 farmProductTag;
        address owner;
        uint totalSupply;
        uint currentSupply;
        bytes32 parentFarmProduct;
        bytes32[] childFarmProduct;
    }
    address FARMER_CONTRACT;

    //This mapping represents farmProduct by mappin farmProductId to it's information
    mapping(bytes32 => FarmProduct) farmProduct;

    //This mapping represents distributor's farm product that he or she had  owned
    mapping(address => bytes32[]) distributorFarmProductOwn;

    //Constructure
    function Exchange()public{

    }

    //This function use to initial farmer contract ONLY USE ONCE
    function initFARMERCONTRACT(address _FARMER_CONTRACT)public{
        require(FARMER_CONTRACT == address(0));
        FARMER_CONTRACT = _FARMER_CONTRACT;
    }

    //This function use to add harvested product to this contract
    function addProduct(bytes32 _farmProductId, uint _totalSupply,address _FARMER_CONTRACT)public{
        require(_FARMER_CONTRACT == FARMER_CONTRACT);
        farmProduct[_farmProductId].farmProductId = _farmProductId;
        farmProduct[_farmProductId].farmProductTag = _farmProductId;
        farmProduct[_farmProductId].owner = msg.sender;
        farmProduct[_farmProductId].totalSupply = _totalSupply;
        farmProduct[_farmProductId].currentSupply = _totalSupply;
    }

    //This function use to create new farmProduct that is divided from the other.
    function divideProduct(bytes32 _farmProductId, uint _amount)private returns(bytes32){
        bytes32 _newFarmProductId = keccak256(_farmProductId,msg.sender,_amount,now);
        require(farmProduct[_newFarmProductId].owner == address(0));
        require(farmProduct[_farmProductId].currentSupply >= _amount);

        farmProduct[_newFarmProductId].farmProductId = _newFarmProductId;
        farmProduct[_newFarmProductId].farmProductTag = farmProduct[_farmProductId].farmProductTag;
        farmProduct[_newFarmProductId].owner = msg.sender;
        farmProduct[_newFarmProductId].totalSupply = _amount;
        farmProduct[_newFarmProductId].parentFarmProduct = _farmProductId;
        farmProduct[_newFarmProductId].currentSupply = _amount;

        farmProduct[_farmProductId].currentSupply -= _amount;
        farmProduct[_farmProductId].childFarmProduct.push(_newFarmProductId);

        return _newFarmProductId;

    }

    //This function is for distributor who wwant to buy product from farmer
    function buyFarmProduct(bytes32 _farmProductId, uint _amount)public payable{
        require(farmProduct[_farmProductId].currentSupply >= _amount);

        distributorFarmProductOwn[msg.sender].push(divideProduct(_farmProductId,_amount));
        farmProduct[_farmProductId].owner.transfer(msg.value);
    }

    //This function use to burn product when sell to retail store such as top
    function retailStore(bytes32 _farmProductId, uint _amount)public{
        require(farmProduct[_farmProductId].currentSupply >= _amount);
        farmProduct[_farmProductId].currentSupply -= _amount;
    }

}
