#include "FbaSetup.h"

FbaSetup::FbaSetup() {
	sqlCon = NULL;
}

FbaSetup::~FbaSetup() {
	if( sqlCon ) {	
		sqlCon->close();
		delete( sqlCon );
	}
}

bool FbaSetup::initialize( std::map<std::string, std::string> & params ) {
	using namespace std;
	int compoundInternalCode;
	int transformationExternalCode;
	int transformationInternalCode = -1;
	double lb;
	iiimap::iterator i_compound;
	std::map<std::string, std::string>::iterator i_map_str_str;
	
	i_map_str_str = params.find( std::string( "setup" ) );
	if( i_map_str_str != params.end() ) {
		setup = i_map_str_str->second;
	}
	else {
		throw( "parameter is missing" );
		return false;
	}
	
	i_map_str_str = params.find( std::string( "stoichs" ) );
	if( i_map_str_str != params.end() ) {
		stoichs_table = i_map_str_str->second;
	}
	else {
		throw( "parameter is missing" );
		return false;
	}

	i_map_str_str = params.find( std::string( "bounds" ) );
	if( i_map_str_str != params.end() ) {
		bounds_table = i_map_str_str->second;
	}
	else {
		throw( "parameter is missing" );
		return false;
	}
	
	i_map_str_str = params.find( std::string( "type" ) );
	if( i_map_str_str != params.end() ) {
		type_table = i_map_str_str->second;
	}
	else {
		throw( "parameter is missing" );
		return false;
	}
	
	i_map_str_str = params.find( std::string( "host" ) );
	if( i_map_str_str != params.end() ) {
		db_host = i_map_str_str->second;
	}
	else {
		throw( "parameter is missing" );
		return false;
	}
	
	i_map_str_str = params.find( std::string( "sqlUser" ) );
	if( i_map_str_str != params.end() ) {
		db_user = i_map_str_str->second;
	}
	else {
		throw( "parameter is missing" );
		return false;
	}
	
	i_map_str_str = params.find( std::string( "sqlPass" ) );
	if( i_map_str_str != params.end() ) {
		db_pass = i_map_str_str->second;
	}
	else {
		throw( "parameter is missing" );
		return false;
	}
	
	i_map_str_str = params.find( std::string( "db" ) );
	if( i_map_str_str != params.end() ) {
		db_data = i_map_str_str->second;
	}
	else {
		throw( "parameter is missing" );
		return false;
	}
	
	try {
		sqlCon = new mysqlpp::Connection( mysqlpp::use_exceptions );
		sqlCon->connect( db_data.c_str(), db_host.c_str(), db_user.c_str(), db_pass.c_str() );
	}
	catch ( mysqlpp::BadQuery & er ) {
		cerr << "SQL connection Error: " << er.what() << endl;	
	}
	catch ( const char * erMsg ) {
		cerr << "SQL Connection Error: " << *erMsg << endl;
	};
	
	mysqlpp::Query sqlQuery = sqlCon->query();
	mysqlpp::Result::iterator i_transformations;
	mysqlpp::Result::iterator i_stoichs;
	lastCompoundInternalCode = -1;
	objectiveCompound = -1;
	problemType = -1;
	
	sqlQuery << "SELECT x0, x1, x2, x3 FROM " << bounds_table << " WHERE p='" << setup << "'";
	mysqlpp::Result transformations = sqlQuery.store();
	
	int totalTransformations = ( int ) transformations.num_rows();
	if( totalTransformations < 2 ) {
		throw( "It is required more than 1 transformation" ) ;
		return false;
	}
	for(	i_transformations = transformations.begin();
			i_transformations != transformations.end();
			++i_transformations ) {
				
		mysqlpp::Row transformation( *i_transformations );
		transformationExternalCode = transformation[0];
		sqlQuery.reset();
		sqlQuery << "SELECT x0, x1, x2 FROM " << stoichs_table << " WHERE p=" << transformationExternalCode;
		
		
		mysqlpp::Result stoichs = sqlQuery.store();

		if( stoichs.num_rows() > 1 ) {
			++transformationInternalCode;
			transformation_i2e.insert( pair<int, int> ( transformationInternalCode, transformationExternalCode ) );
			transformation_e2i.insert( pair<int, int> ( transformationExternalCode, transformationInternalCode ) ); 
			if( (int) transformation.lookup_by_name("x1") ) {
				throw( "Only sources/sinks can be objective function" );
				return false;	
			}

			if( strcmp( transformation.raw_data(2), "0" ) ) {
				if( ( double ) transformation[2] < 0 ) {
					throw( "Bounds cannot be negative" );
					return false;
				}
				transformationLB.insert( pair<int, double>( transformationInternalCode, (double) transformation[2] ) );				
			}
			
			if( strcmp( transformation.raw_data(3), "NULL" ) ) {
				if( ( double ) transformation[3] < 0 ) {
					throw( "Bounds cannot be negative" );
					return false;
				}
				transformationUB.insert( pair<int, double>( transformationInternalCode, (double) transformation[3] ) );				
			}			
			
			for(	i_stoichs = stoichs.begin();
					i_stoichs != stoichs.end();
					i_stoichs++ ) {
				mysqlpp::Row stoich( *i_stoichs );
				compoundInternalCode = FbaSetup::indexCompound( ( int ) stoich.lookup_by_name("x0"), stoich.lookup_by_name("x1"));
				i_compound = compounds.find( compoundInternalCode );
				if( i_compound != compounds.end() ) {
					if( i_compound->second.find( transformationInternalCode ) != i_compound->second.end() ) {
						throw( "compound cannot exist more than once in the same transformation" );
						return false;
					}
				}
				else {
					compounds.insert( pair<int, iimap>( compoundInternalCode, iimap() ) );
					i_compound = compounds.find( compoundInternalCode );
				}	
				i_compound->second.insert( pair<int, int>( transformationInternalCode, (int) stoich.lookup_by_name("x2") ) );
			}	
		}
		else if( stoichs.num_rows() ) {
			i_stoichs = stoichs.begin();
			mysqlpp::Row stoich( *i_stoichs );
			compoundInternalCode =	indexCompound( stoich[0], stoich[1] );
			
			if( (int) stoich.lookup_by_name("x2") == 1 ) {
				if( ( compoundInternalCode == objectiveCompound ) && ( !strcmp( transformation.raw_data(2), "0" ) || !strcmp( transformation.raw_data(3), "NULL" ) ) ) {
					throw( "objective compound cannot have bounded source" );
					return false;
				}
				 
				if( compound_eSrc.find( compoundInternalCode ) == compound_eSrc.end() ) {
					compound_eSrc.insert( pair<int, int>( compoundInternalCode, transformationExternalCode ) );
				}
				else {
					throw( "Every compound can have only one source" );
					return false;	
				}
				if( (int) transformation.lookup_by_name("x1") ) {
					if( problemType > 0 ) {
						throw( "unexpected error" );
						return false;
					}
					else {
						problemType = 3;
					}
					if( objectiveCompound == -1 ) {
						objectiveCompound = compoundInternalCode;	
					}
					else {
						throw( "only one objective compound is allowed" );
						return false;	
					}
					if(	strcmp( transformation.raw_data(2), "0" ) ||
							strcmp( transformation.raw_data(3), "NULL" ) ) {
						throw( "objective compound cannot have limits" );
						return false;
					}
				}
				else {
					if( strcmp( transformation.raw_data(2), "0" ) ) {
						lb = transformation[2];
						if( lb ) {
							if( lb < 0 ) {
								throw( "Bounds cannot be negative" );
								return false;
							}
							if( snkCompoundsLB.find( compoundInternalCode ) != snkCompoundsLB.end() ) {
								throw( "Source and Sink cannot have both minumun set" );
								return false;
							}
							if( srcCompoundsLB.find( compoundInternalCode ) != srcCompoundsLB.end() ) {
								throw( "unexpected error" );
								return false;
							}
							srcCompoundsLB.insert( pair<int, double>( compoundInternalCode, (double) transformation[2] ) );
						}
					}
					
					if( strcmp( transformation.raw_data(3), "NULL" ) ) {
						if( srcCompoundsUB.find( compoundInternalCode ) != srcCompoundsUB.end() ) {
								throw( "unexpected error" );
								return false;	
						}
						if( ( double ) transformation[3] < 0 ) {
							throw( "Bounds cannot be negative" );
							return false;
						}
						srcCompoundsUB.insert( pair<int, double>( compoundInternalCode, (double) transformation[3] ) ); 
					}	
				}
			}
			else if( (int) stoich.lookup_by_name("x2") == -1 ) {
//				std::cout << transformationExternalCode << "--> " << compoundInternalCode << "=" << objectiveCompound << std::endl;
				if( ( compoundInternalCode == objectiveCompound ) && (
					strcmp( transformation.raw_data(2), "0" ) || strcmp( transformation.raw_data(3), "NULL" ) ) ) {
					throw( "Objective compound cannot have bounded sink" );
					return false;
				 }
					 	
				if( compound_eSnk.find( compoundInternalCode ) == compound_eSnk.end() ) {
						compound_eSnk.insert( pair<int, int>( compoundInternalCode, transformationExternalCode ) );
				}
				else {
					throw( "Every compound can have only one sink" );
					return false;
				}
				if( (int) transformation.lookup_by_name("x1") ) {
					if( problemType > 0 ) {
						throw( "unexpected error" );
						return false;
					}
					else {
						problemType = 1;
					}
					
					if( objectiveCompound == -1 ) {
						objectiveCompound = compoundInternalCode;	
					}
					else {
						throw( "only one objective compound is allowed" );
						return false;	
					}
				
					if(	strcmp( transformation.raw_data(2), "0" ) || strcmp( transformation.raw_data(3), "NULL" ) ) {
						throw( "objective compound cannot have bounds" );
						return false;
					}
					
//					if( compound_eSnk.find( compoundInternalCode ) != compound_eSnk.end() ) {
//						throw( "objective compound cannot be sinked" );		
//						return false;
//					}
				}
				else {
					if( strcmp( transformation.raw_data(2), "0" ) ) {
						lb = transformation[2];
						if( lb ) {
							if( lb < 0 ) {
								throw( "Bounds cannot be negative" );
								return false;
							}
							if( srcCompoundsLB.find( compoundInternalCode ) != srcCompoundsLB.end() ) {
								throw( "Source and Sink cannot have both minimun" );
								return false;
							}
							if( snkCompoundsLB.find( compoundInternalCode ) != snkCompoundsLB.end() ) {
								throw( "unexpected error" );
								return false;
							}
							snkCompoundsLB.insert( pair<int, double>( compoundInternalCode, (double) transformation[2] ) );
						}
					}
					
					if( strcmp( transformation.raw_data(3), "NULL" ) ) {
						if( snkCompoundsUB.find( compoundInternalCode ) != snkCompoundsUB.end() ) {
							throw( "unexpected error" );
							return false;	
						}
						if( ( double ) transformation[3] < 0 ) {
							throw( "Bounds cannot be negative" );
							return false;
						}
						snkCompoundsUB.insert( pair<int, double>( compoundInternalCode, (double) transformation[3] ) ); 
					}	
				}
			}
			else {
				throw( "sources/sinks can only be defined with stoich +/- 1" );
				return false;
			}
		}
		else {
			throw( "Transformations/Sources/Sinks require at least 1 compound" );
			return false;
		}
	}
	
	if( problemType && ( objectiveCompound >= 0 ) ) {
		sqlQuery.reset();
		sqlQuery << "SELECT x0 FROM " << type_table << " WHERE p=" << setup;
		mysqlpp::Result optiTypeRes = sqlQuery.store();
		if( optiTypeRes.num_rows() != 1 ) {
			throw( "unexpected error" );
			return false;
		}  
		mysqlpp::Row optiType( *optiTypeRes.begin() );
	
//		std::cout << "prev type " << problemType << std::endl;	
		
		if( (int) optiType[0] == 1 ) {
			problemType += 1;
		}
		else if( (int) optiType[0] != 2 ) {
			throw( "unexpected error" );
			return false;
		} 
	}
	else {
		sqlCon->close();
		delete( sqlCon );
		throw( "objective function is not defined" );
		
		return false;
	}
//	std::cout << "now the test" << std::endl;
	idmap::iterator my_alta;
//	for( my_alta = transformationUB.begin(); my_alta != transformationUB.end(); my_alta++ ) {
//		std::cout << "Transf: " << my_alta->first << " : " << my_alta->second << std::endl;	
//	}
	return true;
}

int FbaSetup::getTransformationCode( int internal ) {
	return ( transformation_i2e.find( internal ) )->second; 
}

int FbaSetup::getObjectiveCode() {
	if( ( problemType == 1 ) || ( problemType == 2 ) ) {
		return ( compound_eSnk.find( objectiveCompound) )->second;	
	}
	else {
		return ( compound_eSrc.find( objectiveCompound ) )->second;
	}
}

bool FbaSetup::isMinimization() {
//	std::cout << "TYPE" << problemType << std::endl;
	if( ( problemType == 2 ) || ( problemType == 3 ) ) {
//		std::cout << "mini" << std::endl;
		return true;
	}
	return false;
}

int FbaSetup::getFlux( int row, int column ) {
	int compound;
	( row < objectiveCompound ) ? ( compound = row ) : ( compound = ( row + 1 ) );
	iiimap::iterator node;
	iimap::iterator edge;
	node = compounds.find( compound );
	edge = (node->second).find( column );
	if( edge != (node->second).end() ) {
		return edge->second;	
	}
	return 0;
}

int FbaSetup::getObjective( int column ) {
	iiimap::iterator node;
	iimap::iterator edge;
	node = compounds.find( objectiveCompound );
	edge = (node->second).find( column );
	if( edge != (node->second).end() ) {
		return edge->second;
	}
	return 0;
}

bool FbaSetup::getCompoundLB( int row, double & lb ) {
	int compound;
	( row < objectiveCompound ) ? ( compound = row ) : ( compound = ( row + 1 ) );
	idmap::iterator i;
	if( compound_eSrc.find( compound ) != compound_eSrc.end() ) {
		i = srcCompoundsUB.find( compound );
		if( i != srcCompoundsUB.end() ) {
			lb = -( i->second );
			return true;
		}
		return false;	
	}
	i = snkCompoundsLB.find( compound );
	if( i != snkCompoundsLB.end() ) {
		lb = i->second;
		return true;	
	}
	lb = 0;
	return true;
}

bool FbaSetup::getCompoundUB( int row, double & ub ) {
	int compound;
	( row < objectiveCompound ) ? ( compound = row ) : ( compound = ( row + 1 ) );
	idmap::iterator i;
	i = srcCompoundsLB.find( compound );
	if( i != srcCompoundsLB.end() ) {
		ub = -( i->second );
		return true;
	}	
	if( compound_eSnk.find( compound ) != compound_eSnk.end() ) {
		i = snkCompoundsUB.find( compound );
		if( i != snkCompoundsUB.end() ) {
			ub = i->second;
			return true;
		}
		return false;
	}
	ub = 0;
	return true;
}

bool FbaSetup::getTransformationLB( int column, double & lb ) { 
	idmap::iterator transformation = transformationLB.find( column );
	if( transformation != transformationLB.end() ) {
		lb = transformation->second;
		return true;
	} 
	return false;	
}

bool FbaSetup::getTransformationUB( int column, double & ub ) {
	idmap::iterator transformation = transformationUB.find( column );	
	if( transformation != transformationUB.end() ) {
		ub = transformation->second;
		return true;
	}
	return false;
}
	
int FbaSetup::indexCompound( int compound, int external ) {
	using namespace std;
	int compoundExternalCode;
	iimap::iterator i_iimap; 
	( external ) ? ( compoundExternalCode = -compound ) : ( compoundExternalCode = compound );
	i_iimap = compound_e2i.find( compoundExternalCode );	
	if( i_iimap != compound_e2i.end() ) { return i_iimap->second; }
	++lastCompoundInternalCode;
	compound_e2i.insert( pair<int, int>( compoundExternalCode, lastCompoundInternalCode ) );
	compound_i2e.insert( pair<int, int>( lastCompoundInternalCode, compoundExternalCode ) );
	return lastCompoundInternalCode;
}	

int FbaSetup::getCompoundSrcCode( int row ) {
	int compound;
	( row < objectiveCompound ) ? ( compound = row ) : ( compound = row + 1 );
	iimap::iterator i;
	i = compound_eSrc.find( compound );
	if( i != compound_eSrc.end() ) {
		return i->second;
	}
	return 0;	
}

int FbaSetup::getCompoundSnkCode( int row ) {
	int compound;
	( row < objectiveCompound ) ? ( compound = row ) : ( compound = row + 1 );
	iimap::iterator i;
	i = compound_eSnk.find( compound );
	if( i != compound_eSnk.end() ) {
		return i->second;	
	}
	return 0;	
}

int FbaSetup::getObjectiveSrcCode() {
	iimap::iterator compound;
//	std::cout << objectiveCompound << std::endl;
	compound = compound_eSrc.find( objectiveCompound );
	if( compound != compound_eSrc.end() ) {
		return compound->second;	
	}
	else {
		throw( "unexpected exception in FbaSetup::getObjectiveSrcCode()" );
		return 0;
	}	
}

int FbaSetup::getObjectiveSnkCode() {
	iimap::iterator compound;
	compound = compound_eSnk.find( objectiveCompound );
	if( compound != compound_eSnk.end() ) {
		return compound->second;
	}
	else {
		throw( "unexpected exception in FbaSetup::getObjectiveSnkCode()" );
		return 0;
	}
}

bool FbaSetup::finalize( std::vector<TransformationFlux> & solution ) {
	std::vector<TransformationFlux>::iterator i;
	std::cout << "OK:" << std::endl;
	for( i = solution.begin(); i != solution.end(); i++ ) {
//		std::cout << i->transformation
//		<< " [" << i->lb << "," << i->ub << "]" 
//		<< "=" << i->flux << std::endl;
		std::cout << i->transformation << ":" << i->flux << std::endl;
	}
	return true;
}

