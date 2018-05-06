/*********************************************
 * OPL 12.8.0.0 Model
 * Author: yansenxu
 * Creation Date: May 3, 2018 at 9:23:41 PM
 *********************************************/
 
//Model of Substrate network
/*
A substrate network is modeled as an undirected graph G=(V,E)  
where V and E represent the set of nodes and edges, respectively. 
C_v denotes the capacity of CPU of v where v∈V. 
B_((u,v) ) denotes the capacity of bandwidth resource of edge (u,v)  
and L_((u,v) ) denotes the latency of edge where (u,v)∈ E. 
*/

//using CP;
int NbOfNodes = ...; //number of nodes in substrate network;
range Nodes = 1..NbOfNodes;
{int} NodeSet = asSet( Nodes );
int CpuCapacity[NodeSet] = ...;
tuple Edge {
	int u;
	int v;
};

{Edge} Edges = ...;
//{Edge} DEdges = ...;
int BandwidthCapacity[Edges] = ...;
int Latency[Edges] = ...;


/*
The types of VNF is presented as Γ and 
φ_γ is the cost for setup VNF γ on one substrate node. (License fee?) 
where γ∈Γ. ω_(γ,v) represents the cost for operating VNF γ 
on substrate network v where v∈V.
*/

int NbOfVNFTypes = ...;
{string} TypeOfVNFs = ...;
int VNFSetupCost[TypeOfVNFs] = ...;
int VNFOpCost[TypeOfVNFs][NodeSet] = ...;

/*
SFC request is modeled as a 5-tuple 
〈s_i,d_i,l_i,b_i,(g_i ) ⃗ 〉 where i is the i-th SFC request.
 s_i: the source node of SFC i in the substrate network where s_i∈V .
d_i: the destination node of SFC i in the substrate network where d_i∈V. We assume that d_i≠s_i
l_i: the maximum latency requirement of SFC i.
b_i: the bandwidth requirement of SFC i.
(g_i ) ⃗: a set of ordered VNFs of SFC i. 
g_(i,j) is the j-th VNF in (g_i ) ⃗.
 g_(i,j,c) is the CPU resource requirement of VNF g_(i,j). 
 g_(i,j,γ) is a Boolean constant to represent whether the j-th VNF in the i-th SFC is VNF γ. 
 We consider that no duplicated VNFs in an SFC, thus g_(i,j_1,γ)+g_(i,j_2,γ)≤1 for ∀i,γ.
*/


int MaxNbOfVNFs = ...;
int NbOfSFCs = ...; //number of sfc requests;

tuple SFC {
	key string name;
	int src;
	int dst;
	int latency;
	int bandwidth;
	{string} VNFList;
}


{SFC} SFCRequests = ...;

int sfc_r[SFCRequests][1..MaxNbOfVNFs][TypeOfVNFs] = ...;
int sfc_c[SFCRequests][1..MaxNbOfVNFs] = ...;

/*
x_(γ,v): A Boolean variable that equals 1 if VNF γ is host on substrate network node v, and 0 otherwise. 
y_(i,j,v): A Boolean variable that equals 1 if the j-th VNF in the i-th SFC is deployed on substrate network node v, and 0 otherwise. 
z_(i,(u,v) ): A Boolean variable that equals 1 if the path of the i-th SFC is travel through the edge (u,v) where (u,v)∈E.

*/

dvar boolean x[TypeOfVNFs][NodeSet];

dvar boolean y[SFCRequests][1..MaxNbOfVNFs][NodeSet];
dvar boolean z[SFCRequests][Edges];


dvar int+ k[SFCRequests][NodeSet];





execute
{
	writeln("Nodes:  ", NodeSet);  
	writeln("CPUCapacity:  ", CpuCapacity);  
	writeln("BandwidthCapacity:  ", BandwidthCapacity);  
	writeln("Latency:  ", Latency);  
	writeln("TypeOfVNFs:  ", TypeOfVNFs); 
	writeln("VNFSetupCost:  ", VNFSetupCost); 
	writeln("VNFOpCost:  ", VNFOpCost); 
	writeln("SFCRequests:  ", SFCRequests); 
	writeln("SFC_r:  ", sfc_r); 
	writeln("SFC_c:  ", sfc_c); 
	for (var r in SFCRequests){
		writeln("SFCRequests size:  ", r.VNFList); 
	}
};
//minimize 
//  sum(t in TypeOfVNFs)
//    sum(v in NodeSet)
//      x[t][v] * VNFSetupCost[t]
//      +
//  sum(r in SFCRequests)
//    sum(i in 1..card(r.VNFList))
//    	sum(t in TypeOfVNFs)
//    	  sum(v in NodeSet)
//      		y[r][i][v] *  VNFOpCost[t][v] ;

//
minimize 
  sum(t in TypeOfVNFs)
    sum(v in NodeSet)
      x[t][v] * VNFSetupCost[t]
      +
    sum(r in SFCRequests)
    	sum(i in 1..card(r.VNFList))
    	  sum(v in NodeSet)
      		y[r][i][v] * sfc_c[r][i] * VNFOpCost[item(r.VNFList, i-1)][v] ;

subject to {
	NodeCapacityCt:
  	forall(v in NodeSet){
  		sum(sfcRequest in SFCRequests)
  		  sum(i in 1..card(sfcRequest.VNFList))
  		    y[sfcRequest][i][v] * sfc_c[sfcRequest][i] <= CpuCapacity[v];
  	}
  	
  	PlacementCt:
  	forall(sfcRequest in SFCRequests){
  		forall(i in 1..card(sfcRequest.VNFList)) {
  			  sum(v in NodeSet: v != sfcRequest.dst && v != sfcRequest.src)
  			     y[sfcRequest][i][v] == 1; // at least one node should host it. 
  		} 	
  	}
  	
  	forall(sfcRequest in SFCRequests){
  		forall(v in NodeSet: v != sfcRequest.dst && v != sfcRequest.src){
  			sum(i in 1..card(sfcRequest.VNFList))  y[sfcRequest][i][v] <= 1; 	//no more than two vnfs are host by one node	
  		}
  	}

  	forall(sfcRequest in SFCRequests){
  		forall(i in 1..card(sfcRequest.VNFList)){
  				forall(v in NodeSet: v != sfcRequest.dst && v != sfcRequest.src){
  					 y[sfcRequest][i][v]==1 => x[item(sfcRequest.VNFList, i-1)][v] == 1;	
//  					 x[item(sfcRequest.VNFList, i-1)][v] == 0 => y[sfcRequest][i][v]== 0;		
  				}  			
  					
  		}  	
  	}
  	
  	
  	
  	BandwidthCt:
  	forall(e in Edges){
  		sum(sfcRequest in SFCRequests)
  	  		z[sfcRequest][e] * sfcRequest.bandwidth <= BandwidthCapacity[e];
  	}
  	
  	LatencyCt:
  	forall(sfcRequest in SFCRequests){
  		sum(e in Edges)
  		  z[sfcRequest][e] * Latency[e] <=  sfcRequest.latency;
  	}

  	SrcFlowCt:
  	forall(sfcRequest in SFCRequests){
  		sum(edge_1 in Edges: edge_1.u == sfcRequest.src)
  			z[sfcRequest][edge_1]
  		-
  		sum(edge_2 in Edges: edge_2.v == sfcRequest.src)
  			z[sfcRequest][edge_2] 		
  		== 1;
  	}
  	DstFlowCt:
  	forall(sfcRequest in SFCRequests){
  		(sum(edge_1 in Edges: edge_1.v == sfcRequest.dst)
  			z[sfcRequest][edge_1])
  		-
  		(sum(edge_2 in Edges: edge_2.u == sfcRequest.dst)
  			z[sfcRequest][edge_2]) 		
  		== 1;
  	}
  	MidNodeFlowCt:
  	forall(sfcRequest in SFCRequests){
  		forall(v in NodeSet: v != sfcRequest.dst && v != sfcRequest.src){
	  		(sum(edge_1 in Edges: edge_1.u == v)
	  			z[sfcRequest][edge_1])
	  		-
	  		(sum(edge_2 in Edges: edge_2.v == v)
	  			z[sfcRequest][edge_2])		
	  		== 0;		
  		}
  	}
  	
  	// One edge can only be used once
  	forall(sfcRequest in SFCRequests) {
  		 forall(e in Edges){
  		 	forall(e2 in Edges: e2.u == e.v && e2.v == e.u){
  		 		  z[sfcRequest][e] + z[sfcRequest][e2] <= 1;
  		 	}		 
  		 }
  	}
  	
  	
  	forall(sfcRequest in SFCRequests) {
  		 forall(v in NodeSet: v != sfcRequest.dst && v != sfcRequest.src){
  		 	forall(i in 1..card(sfcRequest.VNFList)){
  		 		y[sfcRequest][i][v]==1 => sum(e in Edges: e.v == v)
					z[sfcRequest][e] == 1;
		
  			}  		 
  		 }
  	}
  	
  	forall(sfcRequest in SFCRequests) {
  		 forall(v in NodeSet: v != sfcRequest.dst && v != sfcRequest.src){
  		 	forall(i in 1..card(sfcRequest.VNFList)){
  		 		y[sfcRequest][i][v]==1 => sum(e in Edges: e.v == v)
					z[sfcRequest][e] == 1;
  			}  		 
  		 }
  	}
  	
  	
  	// for keeping sfc order
  	forall(sfcRequest in SFCRequests){
  		k[sfcRequest][sfcRequest.src] == 1;  	
	  	forall(e in Edges){
  		 	k[sfcRequest][e.v] - k[sfcRequest][e.u] >= 1 - NbOfNodes * (1 - z[sfcRequest][e]);
  		 }  	
  		 
  	}
	// for keeping sfc order
  	forall(sfcRequest in SFCRequests){
  		forall(i in 1..(card(sfcRequest.VNFList)-1)){
  		 	forall(v in NodeSet:  v != sfcRequest.dst && v != sfcRequest.src){
  				forall(u in NodeSet:  u != sfcRequest.dst && u != sfcRequest.src && u != v){
  					y[sfcRequest][i][v] == 1 && y[sfcRequest][i+1][u] == 1 =>
	  				k[sfcRequest][u] - k[sfcRequest][v] >=0;
  				}		
  			}
  		}  	  	
  	}
  	
  	forall(sfcRequest in SFCRequests){
  		forall(i in 1..card(sfcRequest.VNFList)){
  			forall(j in 7..12){
  			y[sfcRequest][i][j] == 0;	
//  			y[sfcRequest][i][j] == 0;	  			
  			}		
  		}
  	}
  	forall(r in TypeOfVNFs){
  		forall(i in 7..12){
  			x[r][i] == 0;  		
  		}  	
  	}
  	
}




execute {
	writeln("results: z ", z); 
	for(var r in SFCRequests){
		writeln("sfc name:  ", r.name); 	
		for(var e in Edges){
			if(z[r][e]==1)
				writeln("edge ", e);	
		}	
	}
	
	writeln("results: y ", y); 
	
	for(var r in SFCRequests){
		writeln("sfc name:  ", r.name); 
		var count = 0;	
		for(var vnf in r.VNFList){
			count = count + 1;		
			writeln("vnf:  ", vnf); 			
			for(var v in NodeSet){
				if(y[r][count][v]==1)		
					writeln("Node ", v);		
			}	
		}	
	}
};
