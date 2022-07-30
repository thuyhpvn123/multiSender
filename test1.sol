pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract MultiSender is ReentrancyGuard, Ownable{
    using Address for address; 
    uint public remain;
    using SafeERC20 for IERC20;
    event Multisended(uint total, address tokenAddress);
    event MultisendedNft(uint total, address tokenAddress);
    event Decline(address to,uint amount);
    modifier restricted(){
        require(_msgSender() == address(this),"restricted Access");
        _;
    }
    fallback ()external payable {}
    function multisendNft(address token, address [] calldata _receivers,uint [] calldata _nftToId ) external {
        for(uint i=0; i< _nftToId.length;i++){
           IERC721(token).transferFrom(msg.sender,_receivers[i],_nftToId[i]);
        }
        emit MultisendedNft(_nftToId.length, token);
    }
    
    function multisendToken(address token, address[] calldata _to, uint256[] calldata _balances) external  {
        uint256 total = 0;
        IERC20 erc20token = IERC20(token);
        require(_to.length == _balances.length,"Invalid length of input");
        for (uint i=0; i < _to.length; i++) {
            erc20token.safeTransferFrom(msg.sender, _to[i], _balances[i]);
            total += _balances[i];
        }
        emit Multisended(total, token);
    }
    function multisendNativeToken(address[] calldata _to, uint256[] calldata _balances) external payable nonReentrant{
        uint256 total = 0;
        address distributor = _msgSender()  ;
        remain = address(this).balance;
        require(_to.length == _balances.length,"Invalid length of input");
        for (uint i=0; i < _to.length; i++) {
            total += _balances[i] ;
           try this.transfer(payable(_to[i]),_balances[i]){}
           catch{
               address to = _to[i];
               uint amount = _balances[i] ;
               emit Decline(to, amount);
           }
           
        }
        
        if(remain!=0){
          _transfer(payable(distributor),remain);
        }      
        Multisended(total, 0x000000000000000000000000000000000000bEEF);
    }
    function transfer (address payable to, uint amount) public restricted {
        _transfer(to, amount);
    }
    function _transfer(address payable to, uint amount)private {
        Address.sendValue(to,amount);
        // (bool sent, bytes memory data)=to.call{value:amount}("");
        // require(sent,"transaction failed");
    }
    function getBalance()public view returns(uint){
        return address(this).balance;
    }
}
    
