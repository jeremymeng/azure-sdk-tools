import {
    ApiModel,
    ApiItem,
    ApiItemKind,
    ApiDeclaredItem,
    ExcerptTokenKind,
    ReleaseTag
} from '@microsoft/api-extractor-model';

import { stat, readdir, writeFile } from "fs/promises";

import { IApiViewFile, IApiViewNavItem } from './models';
import { TokensBuilder } from './tokensBuilder';
import path = require('path');

function appendMembers(builder: TokensBuilder, navigation: IApiViewNavItem[], item: ApiItem) {
    builder.lineId(item.canonicalReference.toString());
    builder.indent();
    const releaseTag = getReleaseTag(item);
    const parentReleaseTag = getReleaseTag(item.parent);
    if (releaseTag && releaseTag !== parentReleaseTag) {
        if (item.parent.kind === ApiItemKind.EntryPoint) {
            builder.newline();
        }
        builder.annotate(releaseTag);
    }

    if (item instanceof ApiDeclaredItem) {
        if (item.kind === ApiItemKind.Namespace) {
            builder.splitAppend(`declare namespace ${item.displayName} `, item.canonicalReference.toString(), item.displayName);
        }
        for (const token of item.excerptTokens) {
            if (token.kind === ExcerptTokenKind.Reference) {
                builder.typeReference(token.canonicalReference.toString(), token.text);
            }
            else {
                builder.splitAppend(token.text, item.canonicalReference.toString(), item.displayName);
            }
        }
    }

    var navigationItem: IApiViewNavItem;
    var typeKind: string;

    switch (item.kind) {
        case ApiItemKind.Interface:
        case ApiItemKind.Class:
        case ApiItemKind.Namespace:
        case ApiItemKind.Enum:
            typeKind = item.kind.toLowerCase();
            break
        case ApiItemKind.TypeAlias:
            typeKind = "struct";
            break
    }

    if (typeKind) {
        navigationItem = {
            Text: item.displayName,
            NavigationId: item.canonicalReference.toString(),
            Tags: {
                "TypeKind": typeKind
            },
            ChildItems: []
        };
        navigation.push(navigationItem);
    }

    if (item.kind === ApiItemKind.Interface ||
        item.kind === ApiItemKind.Class ||
        item.kind === ApiItemKind.Namespace ||
        item.kind === ApiItemKind.Enum) {
        if (item.members.length > 0) {
            builder
                .punct("{")
                .newline()
                .incIndent()

            for (const member of item.members) {
                appendMembers(builder, navigationItem.ChildItems, member);
            }

            builder
                .decIndent()
                .indent()
                .punct("}")
                .newline();
        }
        else {
            builder
                .punct("{")
                .space()
                .punct("}")
                .newline();
        }
    }
    else {
        builder.newline();
    }
}

function getReleaseTag(item: ApiItem & { releaseTag?: ReleaseTag }): "alpha" | "beta" | undefined {
    switch (item.releaseTag) {
        case ReleaseTag.Beta:
            return "beta";
        case ReleaseTag.Alpha:
            return "alpha";
        default:
            return undefined;
    }
}

async function main() {
    const inputPath = process.argv[2];

    var navigation: IApiViewNavItem[] = [];
    var builder = new TokensBuilder();

    const stats = await stat(inputPath);
    if (stats.isDirectory()) {
        let name: string;
        let packageName: string;
        const files = await readdir(inputPath);
        const pattern = /.*-(?<suffix>.*)\.api.json/;
        for (const file of files) {
            if (!file.endsWith(".api.json")) {
                continue;
            }
            const matches = file.match(pattern);
            let suffix = "<default>";
            if (matches) {
                suffix = matches.groups["suffix"]
            }
            const navItem: IApiViewNavItem = {
                Text: suffix,
                NavigationId: file,
                Tags: {},
                ChildItems: [],
            };
            navigation.push(navItem);
            builder
                .newline()
                .incIndent();

            const apiModel = new ApiModel();
            apiModel.loadPackage(path.join(inputPath, file));

            for (const modelPackage of apiModel.packages) {
                for (const entryPoint of modelPackage.entryPoints) {
                    for (const member of entryPoint.members) {
                        appendMembers(builder, navItem.ChildItems, member);
                    }
                }
            }

            builder
                .decIndent()
                .newline();

            if (!name) {
                name = apiModel.packages[0].name;
                packageName = apiModel.packages[0].name;
            }
        }
        const apiViewFile: IApiViewFile = {
            Name: name,
            Navigation: navigation,
            Tokens: builder.tokens,
            PackageName: packageName,
            VersionString: "1.0.6",
            Language: "JavaScript"
        }
        await writeFile(process.argv[3], JSON.stringify(apiViewFile));

    } else {
        var versionString = "";
        if (inputPath.includes("_")) {
            versionString = inputPath.split("_").pop().replace(".api.json", "");
        }

        const apiModel = new ApiModel();
        apiModel.loadPackage(inputPath);

        for (const modelPackage of apiModel.packages) {
            for (const entryPoint of modelPackage.entryPoints) {
                for (const member of entryPoint.members) {
                    appendMembers(builder, navigation, member);
                }
            }
        }

        var name = apiModel.packages[0].name;
        if (versionString != "") {
            name += "(" + versionString + ")";
        }
        var apiViewFile: IApiViewFile = {
            Name: name,
            Navigation: navigation,
            Tokens: builder.tokens,
            PackageName: apiModel.packages[0].name,
            VersionString: "1.0.5",
            Language: "JavaScript"
        }

        await writeFile(process.argv[3], JSON.stringify(apiViewFile));

    }
}

main().then(() => {
    console.log("Completed");
}).catch(console.error);
