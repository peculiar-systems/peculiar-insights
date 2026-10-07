use std::path::PathBuf;

use tonic::{Request, Response, Status};

use crate::wire::symbolicator_server::Symbolicator;
use crate::wire::{
    InspectRequest, InspectResponse, LookupNativeRequest, LookupNativeResponse, MapSourceRequest,
    MapSourceResponse, RetraceRequest, RetraceResponse, SymbolFormat,
};
use crate::{native, retrace, source_map};

pub struct Adapter;

async fn blocking<T, F>(work: F) -> Result<Response<T>, Status>
where
    T: Send + 'static,
    F: FnOnce() -> Result<T, Status> + Send + 'static,
{
    match tokio::task::spawn_blocking(work).await {
        Ok(outcome) => outcome.map(Response::new),
        Err(failure) => Err(Status::internal(failure.to_string())),
    }
}

#[tonic::async_trait]
impl Symbolicator for Adapter {
    async fn inspect(
        &self,
        request: Request<InspectRequest>,
    ) -> Result<Response<InspectResponse>, Status> {
        let request = request.into_inner();
        let path = PathBuf::from(&request.path);
        let format = request.format();
        let cache = PathBuf::from(&request.cache_directory);
        blocking(move || {
            let entries = match format {
                SymbolFormat::Native => native::inspect(&path, &cache)?,
                SymbolFormat::R8Mapping => retrace::inspect(&path)?,
                SymbolFormat::SourceMap => source_map::inspect(&path)?,
                SymbolFormat::Unspecified => {
                    return Err(Status::invalid_argument("no symbol format was named"));
                }
            };
            Ok(InspectResponse { entries })
        })
        .await
    }

    async fn lookup_native(
        &self,
        request: Request<LookupNativeRequest>,
    ) -> Result<Response<LookupNativeResponse>, Status> {
        let request = request.into_inner();
        blocking(move || {
            let resolved = native::lookup(&PathBuf::from(&request.path), &request.addresses)?;
            Ok(LookupNativeResponse { resolved })
        })
        .await
    }

    async fn retrace(
        &self,
        request: Request<RetraceRequest>,
    ) -> Result<Response<RetraceResponse>, Status> {
        let request = request.into_inner();
        blocking(move || {
            let resolved = retrace::remap(&PathBuf::from(&request.path), &request.frames)?;
            Ok(RetraceResponse { resolved })
        })
        .await
    }

    async fn map_source(
        &self,
        request: Request<MapSourceRequest>,
    ) -> Result<Response<MapSourceResponse>, Status> {
        let request = request.into_inner();
        blocking(move || {
            let resolved = source_map::map(&PathBuf::from(&request.path), &request.positions)?;
            Ok(MapSourceResponse { resolved })
        })
        .await
    }
}

pub fn unreadable(path: &std::path::Path, failure: impl std::fmt::Display) -> Status {
    Status::invalid_argument(format!("{} cannot be read: {failure}", path.display()))
}
