#' Read OMX attributes
#'
#' This function reads the SHAPE and VERSION attributes of an OMX file. This is
#' called by several other functions.
#'
#' @param file full path name of the OMX file being read
#' @return A list containing \code{SHAPE} and \code{VERSION} attributes.
#'
#' @importFrom rhdf5 H5Fopen H5Aopen H5Aread H5Aclose H5Fclose
#' @export
#' @examples 
#' omxfile <- omxr_example("skims.omx")
#' get_omx_attr(omxfile)
#'
get_omx_attr <- function( file ) {
  RootAttr <- list()
	H5File <- rhdf5::H5Fopen( file )
	
	# try and get the shape attribute
	tryCatch({
	  H5Attr <- rhdf5::H5Aopen( H5File, "SHAPE" )
	  RootAttr$SHAPE <- rhdf5::H5Aread( H5Attr )
	  rhdf5::H5Aclose( H5Attr )
	}, 
	error = function(e) {
	  warning("Unable to get shape attribute from OMX file")
	  RootAttr$SHAPE <- NA
	})
	  
	# try to get the OMX version
	tryCatch({
    H5Attr <- rhdf5::H5Aopen( H5File, "OMX_VERSION" )
    RootAttr$VERSION <- rhdf5::H5Aread( H5Attr )
    rhdf5::H5Aclose( H5Attr )
	}, 
	error = function(e) {
	  warning("Unable to get version attribute from OMX file")
	  RootAttr$VERSION <- NA
	})
	
  rhdf5::H5Fclose( H5File )
  RootAttr
}

#' Function to write matrix attribute
#'
#' @param file Full path name of the OMX file to store the matrix in. If this is
#'   a new matrix file, see \link{create_omx}.
#' @param name Name of the matrix in the OMX object.
#' @param attr_name Name of the attribute.
#' @param value Attribute value
#' 
#' @return None
#'
#' @importFrom rhdf5 H5Fopen H5Gopen H5Dopen h5writeAttribute H5Dclose H5Gclose
#'   H5Fclose
#'
#' @export
write_matrix_attr <- function( file, name, attr_name, value) {
    H5File <- rhdf5::H5Fopen(file)
    H5Group <- rhdf5::H5Gopen( H5File, "data" )
    H5Data <- rhdf5::H5Dopen( H5Group, name )
    rhdf5::h5writeAttribute(value, H5Data, attr_name)

    #Close everything up before exiting
    rhdf5::H5Dclose( H5Data )
    rhdf5::H5Gclose( H5Group )
    rhdf5::H5Fclose( H5File )
}


#' List the contents of an OMX file
#'
#' @param file The path to the OMX file.
#'
#' @return A list with 5 elements:
#' \describe{
#'   \item{Version}{the OMX version number}
#'   \item{Rows}{The number of rows in the matrix.}
#'   \item{Columns}{The number of columns in the matrix.}
#'   \item{Matrices}{A \code{data.frame} identifying the matrices and their
#'   attributes}
#'   \item{Lookups}{A \code{data.frame} identifying the lookups and their
#'   attributes.}
#'  }
#' @importFrom rhdf5 h5ls H5Fopen H5Gopen H5Dopen H5Aexists H5Aopen H5Aread
#'   H5Aclose H5Dclose H5Gclose H5Fclose
#'
#' @export
#' @examples
#' omxfile <- omxr_example("skims.omx")
#' list_omx(omxfile)
#'
list_omx <- function( file ) {
  #Get the version and shape information
	RootAttr <- get_omx_attr( file )
	Version <- RootAttr$VERSION
	Shape <- RootAttr$SHAPE
  #Use the h5ls function to read the contents of the file
  Contents <- rhdf5::h5ls( file )
  MatrixContents <- Contents[ Contents$group == "/data", ]
  LookupContents <- Contents[ Contents$group == "/lookup", ]
  #Read the matrix attribute information
  Names <- MatrixContents$name
  Types <- MatrixContents$dclass
  H5File <- rhdf5::H5Fopen( file )
  H5Group <- rhdf5::H5Gopen( H5File, "data" )
  MatAttr <- list()

  for( i in 1:length(Names) ) {
		Attr <- list(type="matrix")
    H5Data <- rhdf5::H5Dopen( H5Group, Names[i] )
    if(rhdf5::H5Aexists(H5Data, "NA")) {
      H5Attr <- rhdf5::H5Aopen( H5Data, "NA" )
      Attr$navalue <- rhdf5::H5Aread( H5Attr )
      rhdf5::H5Aclose( H5Attr )
    }
    if(rhdf5::H5Aexists(H5Data, "Description")) {
      H5Attr <- rhdf5::H5Aopen( H5Data, "Description" )
      Attr$description <- rhdf5::H5Aread( H5Attr )
      rhdf5::H5Aclose( H5Attr )
    }
    MatAttr[[Names[i]]] <- Attr
    rhdf5::H5Dclose( H5Data )
    rm( Attr )
  }

  rhdf5::H5Gclose( H5Group )
  rhdf5::H5Fclose( H5File )

  MatAttr <- do.call( rbind, lapply( MatAttr, function(x) data.frame(x) ) )
  rm( Names, Types )

  #Read the lookup attribute information
  H5File <- rhdf5::H5Fopen( file )
  H5Group <- rhdf5::H5Gopen( H5File, "lookup" )
  Names <- LookupContents$name
  Types <- LookupContents$dclass
  LookupAttr <- list()

	if(length(Names)>0){
	  for( i in 1:length(Names) ) {
	    Attr <- list()
	    H5Data <- rhdf5::H5Dopen( H5Group, Names[i] )

	    if( rhdf5::H5Aexists( H5Data, "DIM" ) ) {
	      H5Attr <- rhdf5::H5Aopen( H5Data, "DIM" )
	      Attr$lookupdim <- rhdf5::H5Aread( H5Attr )
	      rhdf5::H5Aclose( H5Attr )
	    } else {
	      Attr$lookupdim <- ""
	    }

	    if( rhdf5::H5Aexists( H5Data, "Description" ) ) {
	      H5Attr <- rhdf5::H5Aopen( H5Data, "Description" )
	      Attr$description <- rhdf5::H5Aread( H5Attr )
	      rhdf5::H5Aclose( H5Attr )
	    } else {
	      Attr$description <- ""
	    }

	    LookupAttr[[Names[i]]] <- Attr
	    rhdf5::H5Dclose( H5Data )
	    rm( Attr )
		}

	  rhdf5::H5Gclose( H5Group )
	  rhdf5::H5Fclose( H5File )

	  LookupAttr <- do.call( rbind, lapply( LookupAttr, function(x) data.frame(x) ) )
	  rm( Names, Types )
	} else {
	  rhdf5::H5Gclose(H5Group)
	  rhdf5::H5Fclose(H5File)
	  
	}
  

  #Combine the results into a list
  if(length(MatAttr)>0) {
    MatInfo <- cbind( MatrixContents[,c("name","dclass","dim")], MatAttr )
  } else {
    MatInfo <- MatrixContents[,c("name","dclass","dim")]
  }

	if(length(LookupAttr)>0) {
    LookupInfo <- cbind( LookupContents[,c("name","dclass","dim")], LookupAttr )
  } else {
    LookupInfo <- LookupContents[,c("name","dclass","dim")]
  }

  list(
    OMXVersion=Version,
    Rows=Shape[1], Columns=Shape[2],
    Matrices=MatInfo, Lookups=LookupInfo
  )
}
