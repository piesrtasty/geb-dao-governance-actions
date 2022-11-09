pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../SimulateProposalBase.t.sol";

contract Proposal13Test is SimulateProposalBase {
    function test_proposal_13() public onlyFork {
        MerkleDistributorFactoryLike merkleDistFactory = MerkleDistributorFactoryLike(0xb5Ed650eF207e051453B68A2138D7cb67CC85E41);

        // packing data for the proposal
        address[] memory targets = new address[](2);
        bytes[] memory calldatas = new bytes[](2);

        address[1] memory receivers = [
            address(0x0a453F46f8AE9a99b2B901A26b53e92BE6c3c43E)
        ];

        uint[1] memory amounts = [
            uint(251 ether)
        ];


        // dao payroll
        for (uint i; i < receivers.length; ++i) {
            targets[i] = govActions;
            calldatas[i] = abi.encodeWithSelector(
                bytes4(keccak256("transferERC20(address,address,address,uint256)")),
                0x7a97E2a5639f172b543d86164BDBC61B25F8c353, // GEB_DAO_TREASURY
                address(prot),
                receivers[i],
                amounts[i]
            );
        }

        // monthly distro
        targets[1] = 0xe3Da59FEda69B4D83a10EB383230AFf439dd802b; // system govActions
        calldatas[1] = abi.encodeWithSignature(
            "deployDistributorAndSendTokens(address,bytes32,uint256)",
            0xb5Ed650eF207e051453B68A2138D7cb67CC85E41,                            // Merkle distributor factory
            0xb7a26aae3c54f0f91d1ae166f418fa52a87772cf0ef907f252ae261cd7a0a780,    // Merkle root
            4959792593448000000000                                                 // Amount distributed - 0xc9a95ee2964caee600
        );

        // fetching previous balances
        uint[2] memory prevBalances;
        for (uint i; i < receivers.length; ++i) {
            prevBalances[i] = prot.balanceOf(receivers[i]);
        }

        uint256 savedNonce = merkleDistFactory.nonce();

        // propose / execute proposal
        _passProposal(targets, calldatas);

        // testing balances
        for (uint i; i < receivers.length; ++i) {
            assertEq(prot.balanceOf(receivers[i]), prevBalances[i] + amounts[i]);
        }

        // testing distro
        assertEq(savedNonce + 1, merkleDistFactory.nonce());
        MerkleDistributorLike distributor = MerkleDistributorLike(merkleDistFactory.distributors(savedNonce + 1));

        assertEq(distributor.merkleRoot(), 0xb7a26aae3c54f0f91d1ae166f418fa52a87772cf0ef907f252ae261cd7a0a780);
        assertEq(prot.balanceOf(address(distributor)), 4959792593448000000000);

        _logData(targets, calldatas);
        revert();
    }
}