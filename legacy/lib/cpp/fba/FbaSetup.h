#ifndef _FBASETUP_H_
#define _FBASETUP_H_

#include <mysql++/mysql++.h>
#include "TransformationFlux.h"
#include <iostream>
#include <vector>
#include <string>
#include <map>

/* The logic behind:
 * objective function cannot have bounds
 * if the problem is: maximization of sink- TYPE 1
 * 	source cannot exist
 * 	maximize row
 * 	optimal solution should be positive
 * 	excretion flux = optimal solution
 * elsif the problem is: minimization of sink- TYPE 2
 *	source cannot exist
 *	minimize row
 *	optimal solution should be negative
 *	excretion flux = -optimal solution
 * elsif the problem is: maximization of source- TYPE 3
 * 	sink cannot exist
 * 	minimize row
 * 	optimal solution should be negative
 * 	uptake flux = -optimal solution
 * elsif the problem is: minimization of source- TYPE 4 
 * 	sink cannot exist
 * 	maximize row
 * 	optimal solution should be negative
 * 	uptake flux = -optimal solution
 * endif
 */
	

class FbaSetup {
	public:
		//Methods
		FbaSetup();
		virtual ~FbaSetup();
		bool initialize( std::map<std::string, std::string> & );
		bool finalize( std::vector<TransformationFlux> & solution );
		int getTotalTransformations() { return transformation_i2e.size(); }
		int getTotalCompounds() { return ( compound_i2e.size() - 1 ); }
		int getFlux( int row, int column );
		int getObjective( int column );
		bool getTransformationUB( int column, double & ub );
		bool getTransformationLB( int column, double & lb );
		bool getCompoundUB( int row, double & ub );
		bool getCompoundLB( int row, double & lb );
		bool getObjectiveVector();
		bool getCompoundVector( int row );
		bool isMinimization();
		int getTransformationCode( int internal );
		int getObjectiveCode();
		int getCompoundSrcCode( int row );
		int getCompoundSnkCode( int row );
		int getObjectiveSrcCode();
		int getObjectiveSnkCode();
		
	private:
		//Types	
		typedef std::map<int, int> iimap;
		typedef std::map<int, double> idmap;
		typedef std::map<int, iimap> iiimap;
		//Methods
		int indexCompound( int compound, int external ); 
		//Attributes
		int lastCompoundInternalCode;
		int problemType;
		int objectiveCompound;
		std::string setup;
		std::string db_host;
		std::string db_user;
		std::string db_pass;
		std::string db_data;
		std::string bounds_table;
		std::string stoichs_table;
		std::string type_table;
		iimap compound_e2i;
		iimap compound_i2e;
		iimap compound_eSrc;
		iimap compound_eSnk;
		idmap snkCompoundsLB;
		idmap snkCompoundsUB;
		idmap srcCompoundsLB;
		idmap srcCompoundsUB;
		idmap transformationLB;
		idmap transformationUB;
		iimap transformation_i2e;
		iimap transformation_e2i;
		iiimap compounds;
		//Pointers
		mysqlpp::Connection * sqlCon;
};

#endif //_FBASETUP_H_
