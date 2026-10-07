mod native;
mod retrace;
mod service;
mod source_map;

mod wire {
    tonic::include_proto!("peculiar.insights.v1");
}

use std::path::PathBuf;
use std::process::ExitCode;

use tokio::net::UnixListener;
use tokio_stream::wrappers::UnixListenerStream;
use tonic::transport::Server;

use crate::service::Adapter;
use crate::wire::symbolicator_server::SymbolicatorServer;

fn socket_of(arguments: &[String]) -> Option<PathBuf> {
    match arguments {
        [flag, path] if flag == "--socket" => Some(PathBuf::from(path)),
        _ => None,
    }
}

#[tokio::main]
async fn main() -> ExitCode {
    let arguments: Vec<String> = std::env::args().skip(1).collect();
    let Some(socket) = socket_of(&arguments) else {
        eprintln!("usage: peculiar-insights-symbolicator --socket <path>");
        return ExitCode::from(2);
    };
    match serve(socket).await {
        Ok(()) => ExitCode::SUCCESS,
        Err(failure) => {
            eprintln!("peculiar-insights-symbolicator: {failure}");
            ExitCode::FAILURE
        }
    }
}

async fn serve(socket: PathBuf) -> Result<(), Box<dyn std::error::Error>> {
    if socket.exists() {
        std::fs::remove_file(&socket)?;
    }
    let listener = UnixListener::bind(&socket)?;
    Server::builder()
        .add_service(SymbolicatorServer::new(Adapter))
        .serve_with_incoming_shutdown(UnixListenerStream::new(listener), stopped())
        .await?;
    Ok(())
}

async fn stopped() {
    let mut terminate =
        match tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()) {
            Ok(signal) => signal,
            Err(_) => return std::future::pending().await,
        };
    tokio::select! {
        _ = terminate.recv() => {}
        _ = tokio::signal::ctrl_c() => {}
    }
}
