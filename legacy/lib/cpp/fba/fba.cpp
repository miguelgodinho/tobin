/* (C) Miguel Godinho de Almeida ( miguel@gbf.de ) 2005
*-------------------------------------------------------------------------*/

#include "FbaSetup.h"
#include "TransformationFlux.h"
#include "OsiClpSolverInterface.hpp"
#include "CoinPackedVector.hpp"
#include "CoinPackedMatrix.hpp"
#include <iostream>
#include <vector>
#include <string>
#include <map>

using namespace std;

int main( int argc, char* argv[] ) {
	int i;
	map<string, string> params;
	string argument, key, value;
	set< string> requiredParams, optionalParams, maskedParams;
	set<string>::iterator i_set_str;
	requiredParams.insert( string( "stoichs" ) );
	requiredParams.insert( string( "user" ) );
	requiredParams.insert( string( "setup" ) );
	requiredParams.insert( string( "bounds" ) );
	requiredParams.insert( string( "type" ) );
	requiredParams.insert( string( "db" ) );
	requiredParams.insert( string( "host" ) );
	requiredParams.insert( string( "sqlUser" ) ); 
	optionalParams.insert( string( "sqlPass" ) );
	
	for( i = 1; i < argc; i++ ) {
		argument = argv[i];
		string::size_type idx = argument.find( '=' );
		if( ( idx == string::npos) || ( argument[0] != '-' ) || ( argument[1] != '-' ) ) {
			cerr << "invalid arguments" << endl;	
			return -1;
		}
		else {
			key		= argument.substr( 2, idx-2 );
			value	= argument.substr( idx+1); 
			if( params.find( key ) != params.end() ) {
				cerr << key << " is assigned more than once" << endl;	
				return -1;
			}
			else if(	( requiredParams.find( key ) == requiredParams.end() ) && 
						( optionalParams.find( key ) == optionalParams.end() ) ) {
				cerr << key << " is unkown argument" << endl;	
				return -1;
			}
			else {
				params.insert( pair<string, string>( key, value ) );	
			}	
		}
	}
	for( i_set_str = requiredParams.begin(); i_set_str != requiredParams.end(); i_set_str++ ) {
		if( params.find( *i_set_str ) == params.end() ) {
			cerr << *i_set_str << " is req. param" << endl;
			return -1;
		}
	}
	for( i_set_str = optionalParams.begin(); i_set_str != optionalParams.end(); i_set_str++ ) {
		if( params.find( *i_set_str ) == params.end() ) {
			params.insert( pair<string, string>( *i_set_str, string( "" ) ) );
		}
	}
	try {
		FbaSetup fbaSetup;
//		cout << "step0" << endl;
		fbaSetup.initialize( params );
		OsiClpSolverInterface osi;
		CoinPackedMatrix matrix(false, 0, 0);
		
		int col, row;
		double value;
		int cols = fbaSetup.getTotalTransformations();
		int rows = fbaSetup.getTotalCompounds();
		double objective[cols];
		double row_lb[rows];
		double row_ub[rows];
		double col_lb[cols];
		double col_ub[rows];
		
		matrix.setDimensions( 0, cols );	
		
		for ( col = 0; col < cols; col++ ) {
			objective[col] = fbaSetup.getObjective( col );	
		}	
			
		for ( row = 0; row < rows; row++ ) {
			( fbaSetup.getCompoundLB( row, value ) ) ? ( row_lb[row] = value ) : ( row_lb[row] = -osi.getInfinity() );	
			CoinPackedVector vector;
			
//			cout << "ROW " << row << " {";
			for ( col = 0; col < cols; col++ ) {
				value = fbaSetup.getFlux( row, col );
				vector.insert(col, value );				
//				cout << " " << value; 
			}
//			cout << "}" << endl;
			matrix.appendRow( vector );
		}	
		
		for ( row = 0; row < rows; row++ ) {
			( fbaSetup.getCompoundUB( row, value ) ) ? ( row_ub[row] = value ) : ( row_ub[row] = osi.getInfinity() );	
//			cout << "Row " << row << ": [" << row_lb[row] << ", " << row_ub[row] << "]" << endl;
		}	
				
		for ( col = 0; col < cols; col++ ) {
			( fbaSetup.getTransformationLB( col, value ) ) ? ( col_lb[col] = value ) : ( col_lb[col] = 0 );	
		}	
		
		for ( col = 0; col < cols; col++ ) {
			( fbaSetup.getTransformationUB( col, value ) ) ? ( col_ub[col] = value ) : ( col_ub[col] = osi.getInfinity() );	
//			cout << "Col " << col << ": [" << col_lb[col] << ", " << col_ub[col] << "]" << endl;
		}			
		
		osi.loadProblem( matrix, col_lb, col_ub, objective, row_lb, row_ub );
		if ( fbaSetup.isMinimization() ) {
//			cout << "Minimizing " << fbaSetup.getObjectiveCode() << endl;
		}		
		else {
			osi.setObjSense( -1 );
//			cout << "Maximizing " << fbaSetup.getObjectiveCode() << endl;
		}
		
//		osi.writeMps( "example" );	
		osi.initialSolve();
		if ( !osi.isAbandoned() ) {
			vector<TransformationFlux> resultMatrix;
			TransformationFlux currentTransf;
			const double * results;
			double objectiveFlux = osi.getObjValue();
			currentTransf.objective = true;
			currentTransf.lb = 0;
			currentTransf.ub = -1;
			if ( ( currentTransf.transformation = fbaSetup.getObjectiveSrcCode() ) ) {
				( objectiveFlux < 0 ) ? ( currentTransf.flux = -objectiveFlux ) : ( currentTransf.flux = 0 );
			}
			else {
				return -1;
			}
			resultMatrix.push_back( currentTransf );
			
			if ( ( currentTransf.transformation = fbaSetup.getObjectiveSnkCode() ) ) {
				( objectiveFlux > 0 ) ? ( currentTransf.flux = objectiveFlux ) : ( currentTransf.flux = 0 );
			}
			else {
				return -1;
			}
			resultMatrix.push_back( currentTransf );
			
			currentTransf.objective = false;
		
			results = osi.getRowActivity();	
			for ( row = 0; row < rows; row++ ) {	
				if ( ( currentTransf.transformation = fbaSetup.getCompoundSrcCode( row ) ) ) {
					( results[row] < 0 ) ? ( currentTransf.flux = -results[row] ) : ( currentTransf.flux = 0 );
					if ( row_lb[row] < 0 ) {
						( row_ub[row] < 0 ) ? ( currentTransf.lb = -row_ub[row] ) : ( currentTransf.lb = 0 );
						( -row_lb[row] == osi.getInfinity() ) ? ( currentTransf.ub = - 1 ) : ( currentTransf.ub = -row_lb[row] );
					}
					else {
						currentTransf.lb = 0;
						currentTransf.ub = 0;	
					}
					resultMatrix.push_back( currentTransf );
				}
				
				if ( ( currentTransf.transformation = fbaSetup.getCompoundSnkCode( row ) ) ) {
					( results[row] > 0 ) ? ( currentTransf.flux = results[row] ) : ( currentTransf.flux = 0 );
					if ( row_ub[row] > 0 ) {
						( row_lb[row] > 0 ) ? ( currentTransf.lb = row_lb[row] ) : ( currentTransf.lb = 0 );
						( row_ub[row] == osi.getInfinity() ) ? ( currentTransf.ub = -1 ) : ( currentTransf.ub = row_ub[row] );
					}
					else {
						currentTransf.lb = 0;
						currentTransf.ub = 0;
					} 
					resultMatrix.push_back( currentTransf );
				}	
			}
			
			results = osi.getColSolution();	
			for ( col = 0; col < cols; col++ ) {
				currentTransf.transformation = fbaSetup.getTransformationCode( col );
				currentTransf.flux = results[col];
				( col_lb[col] == osi.getInfinity() ) ? ( currentTransf.lb = -1 ) : ( currentTransf.lb = col_lb[col] );
				( col_ub[col] == osi.getInfinity() ) ? ( currentTransf.ub = -1 ) : ( currentTransf.ub = col_ub[col] ); 
				resultMatrix.push_back( currentTransf );
			}
			
			fbaSetup.finalize( resultMatrix );
		}
		else {
			return -1;
		}
	}
	catch ( const char* error ) {
		cerr << error << endl;
		return -1;
	};
	return 0;
};

